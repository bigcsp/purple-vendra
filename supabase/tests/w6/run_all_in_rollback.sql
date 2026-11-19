-- =====================================================================
-- W6: run every W6 suite against the CURRENT seed version, inside one block
-- that is always rolled back. STAGING / LOCAL ONLY.
--
-- 1. seed_guard_checks  (G00-G15: guards, atomicity, duplicates, passwords)
-- 2. remove the existing seed data, load supabase/seed.sql fresh
-- 3. seed_checks        (S01-S32)
-- 4. anonymizer_checks  (A01-A29)
-- then everything is undone; only the results survive (copied out first).
--
-- Needs temp table w6_scripts with rows: seed, anonymize, seed_checks,
-- anonymizer_checks, seed_guard_checks (each SHA-256 checked by the caller),
-- and purple.test_target set to this project's ref (or 'local').
-- Before/after proof that nothing changed: staging_fingerprint.sql.
-- =====================================================================
create temp table if not exists w6_results (n serial, suite text, name text, ok boolean, detail text);
truncate w6_results;

do $all$
declare
  c_prod_ref constant text := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  target text := nullif(current_setting('purple.test_target', true), '');
  v_url  text;
  kept   text[];
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'project_url';
  if target is null or v_url is null or position(c_prod_ref in lower(coalesce(v_url, '') || target)) > 0
     or not ((target = 'local' and v_url ~ '^https?://(127\.0\.0\.1|localhost|kong|host\.docker\.internal)(:[0-9]+)?/?$')
             or (target = any (c_staging_refs) and v_url ~ ('^https://' || target || '\.supabase\.co/?$'))) then
    raise exception 'run_all_in_rollback refused: not an approved staging/local database';
  end if;

  begin
    execute (select body from w6_scripts where name = 'seed_guard_checks');

    -- fresh load of the current seed version
    delete from vault.secrets where name = 'purple_seed_marker';
    delete from public.reviews; delete from public.payouts; delete from public.reseller_commissions; delete from public.disputes;
    delete from public.bookings; delete from public.orders; delete from public.checkouts; delete from public.featured_purchases;
    delete from public.reports; delete from public.risk_flags; delete from public.seller_verifications;
    delete from auth.users where email like '%@seed.purple.test';
    perform set_config('purple.seed_target', target, true);
    execute (select body from w6_scripts where name = 'seed');
    insert into w6_results (suite, name, ok, detail) values ('load', 'L01 current seed loaded fresh', true, null);

    execute (select body from w6_scripts where name = 'seed_checks');
    execute (select body from w6_scripts where name = 'anonymizer_checks');

    kept := array(select suite || '|' || name || '|' || ok::text || '|' || coalesce(detail, '') from w6_results order by n);
    raise exception using errcode = 'P0W66', message = 'w6 run_all rollback';
  exception when sqlstate 'P0W66' then null;
  end;

  insert into w6_results (suite, name, ok, detail)
  select split_part(r, '|', 1), split_part(r, '|', 2), split_part(r, '|', 3)::boolean,
         substr(r, length(split_part(r, '|', 1)) + length(split_part(r, '|', 2)) + length(split_part(r, '|', 3)) + 4)
  from unnest(kept) r;
end $all$;
