-- =====================================================================
-- W6 seed guard, duplicate and atomicity tests (G00-G15).
-- STAGING / LOCAL ONLY. Destructive steps happen ONLY inside a block that is
-- always rolled back: the database ends exactly as it started.
-- Needs: the seed text in temp table w6_scripts(name = 'seed'),
--        and purple.test_target = this project's ref (or 'local').
-- Results go to w6_results (suite 'seed_guard').
-- =====================================================================
create temp table if not exists w6_results (n serial, suite text, name text, ok boolean, detail text);
delete from w6_results where suite = 'seed_guard';

do $test$
declare
  c_prod_ref constant text := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  seed   text := (select body from w6_scripts where name = 'seed');
  target text := nullif(current_setting('purple.test_target', true), '');
  v_url  text;
  res    text[] := '{}';
  stripped text;
  v_err text; v_n bigint; v_m jsonb;
  c_pw constant text := 'W6-test-only-password-not-real';

  -- remove all seed data (and the marker); used only inside the rolled-back block below
  wipe constant text := $w$
    delete from vault.secrets where name = 'purple_seed_marker';
    delete from public.reviews; delete from public.payouts; delete from public.reseller_commissions; delete from public.disputes;
    delete from public.bookings; delete from public.orders; delete from public.checkouts; delete from public.featured_purchases;
    delete from public.reports; delete from public.risk_flags; delete from public.seller_verifications;
    delete from auth.users where email like '%@seed.purple.test';
  $w$;
begin
  -- Safety: these tests only ever run on an approved staging project or a local database.
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'project_url';
  if target is null or v_url is null or position(c_prod_ref in lower(coalesce(v_url, '') || target)) > 0
     or not ((target = 'local' and v_url ~ '^https?://(127\.0\.0\.1|localhost|kong|host\.docker\.internal)(:[0-9]+)?/?$')
             or (target = any (c_staging_refs) and v_url ~ ('^https://' || target || '\.supabase\.co/?$'))) then
    raise exception 'seed_guard_checks refused: not an approved staging/local database';
  end if;

  -- G00: the file is a single statement (one DO block) => atomic in psql, CLI and SQL editor
  stripped := btrim(array_to_string(array(select l from unnest(string_to_array(seed, E'\n')) l where l !~ '^\s*--'), E'\n'));
  res := res || ('G00|' || (left(stripped, 9) = 'do $seed$' and right(stripped, 11) = 'end $seed$;'
                            and (length(seed) - length(replace(seed, '$seed$', ''))) / 6 = 2)::text
                 || '|seed.sql is exactly one DO block (one statement)');

  begin   -- ================================================ everything below is rolled back
    execute wipe;
    select count(*) into v_n from auth.users where email like '%@seed.purple.test';
    res := res || ('G00b|' || (v_n = 0)::text || '|test start: seed data removed inside the rolled-back block (' || v_n || ' seed accounts)');

    -- Production / configuration refusals
    begin perform set_config('purple.seed_target', '', true); execute seed; res := res || 'G01|false|seed ran without a target';
    exception when others then res := res || ('G01|' || (sqlerrm like 'seed refused: purple.seed_target is not set%')::text || '|' || sqlerrm); end;
    begin perform set_config('purple.seed_target', c_prod_ref, true); execute seed; res := res || 'G02|false|seed ran with the production ref';
    exception when others then res := res || ('G02|' || (sqlerrm like 'seed refused: the target is the production project%')::text || '|' || sqlerrm); end;
    begin perform set_config('purple.seed_target', 'abcdefghijklmnopqrst', true); execute seed; res := res || 'G03|false|seed ran with another ref';
    exception when others then res := res || ('G03|' || (sqlerrm like 'seed refused: target%does not match%')::text || '|' || sqlerrm); end;
    begin perform set_config('purple.seed_target', left(target, 7), true); execute seed; res := res || 'G04|false|seed ran with a partial ref';
    exception when others then res := res || ('G04|' || (sqlerrm like 'seed refused: target%does not match%')::text || '|' || sqlerrm); end;
    begin perform set_config('purple.seed_target', 'local', true); execute seed; res := res || 'G05|false|local target accepted on a hosted project';
    exception when others then res := res || ('G05|' || (sqlerrm like 'seed refused: target is local%')::text || '|' || sqlerrm); end;
    begin
      delete from vault.secrets where name = 'project_url';
      perform set_config('purple.seed_target', target, true); execute seed;
      res := res || 'G06|false|seed ran with no Vault project_url';
    exception when others then res := res || ('G06|' || (sqlerrm like 'seed refused: Vault project_url is missing%')::text || '|' || sqlerrm); end;
    begin
      perform set_config('purple.seed_target', target, true);
      execute 'set local role authenticated';
      execute seed;
      res := res || 'G07|false|seed ran with Vault unreadable';
    exception when others then res := res || ('G07|' || (sqlerrm like 'seed refused: Vault project_url cannot be read%')::text || '|' || sqlerrm); end;
    begin
      perform vault.update_secret((select id from vault.secrets where name = 'project_url'), 'https://' || c_prod_ref || '.supabase.co');
      perform set_config('purple.seed_target', target, true); execute seed;
      res := res || 'G08|false|seed ran on a database whose project_url is production';
    exception when others then res := res || ('G08|' || (sqlerrm like 'seed refused: this database is the production project%')::text || '|' || sqlerrm); end;
    begin
      insert into auth.users (instance_id, id, aud, role, email) values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', 'someone@example.com');
      perform set_config('purple.seed_target', target, true); execute seed;
      res := res || 'G09|false|seed ran with a real account present';
    exception when others then res := res || ('G09|' || (sqlerrm like 'seed refused: this database has real (non-seed) accounts%')::text || '|' || sqlerrm); end;

    -- Atomicity: force a failure in the middle (messages section) and check nothing is left behind
    begin
      alter table public.messages add constraint w6_force_fail check (false) not valid;
      begin
        perform set_config('purple.seed_target', target, true);
        execute seed;
        v_err := 'did not fail';
      exception when others then v_err := sqlerrm;
      end;
      select (select count(*) from auth.users where email like '%@seed.purple.test')
           + (select count(*) from public.listings) + (select count(*) from public.buyer_requests)
           + (select count(*) from vault.secrets where name = 'purple_seed_marker') into v_n;
      res := res || ('G10|' || (v_err like '%w6_force_fail%' and v_n = 0)::text
                     || '|failure mid-seed (' || v_err || ') left ' || v_n || ' rows (accounts + listings + requests + marker)');
      raise exception using errcode = 'P0W65', message = 'undo G10 constraint';
    exception when sqlstate 'P0W65' then null;
    end;

    -- Successful run (with a test password for the non-admin accounts)
    perform set_config('purple.seed_target', target, true);
    perform set_config('purple.seed_password', c_pw, true);
    execute seed;
    perform set_config('purple.seed_password', '', true);
    select decrypted_secret::jsonb into v_m from vault.decrypted_secrets where name = 'purple_seed_marker';
    res := res || ('G11|' || ((select count(*) from auth.users where email like '%@seed.purple.test') = 32 and v_m ->> 'status' = 'complete')::text
                   || '|clean retry after the failed run succeeded: 32 accounts, marker ' || coalesce(v_m::text, 'missing'));
    res := res || ('G12|' || ((select extensions.crypt(c_pw, encrypted_password) <> encrypted_password from auth.users where email = 'admin@seed.purple.test')
                              and (select bool_and(extensions.crypt(c_pw, encrypted_password) = encrypted_password) from auth.users
                                   where email like '%@seed.purple.test' and email <> 'admin@seed.purple.test'))::text
                   || '|admin does NOT get the shared test password; the 31 test accounts do');
    res := res || ('G13|' || (select bool_and(encrypted_password like '$2a$10$%') and count(distinct encrypted_password) = 32
                              from auth.users where email like '%@seed.purple.test')::text || '|all 32 hashes bcrypt cost 10, all distinct (salted)');
    res := res || ('G13b|' || (select count(*) = 0 from vault.decrypted_secrets where position(c_pw in decrypted_secret) > 0)::text
                   || '|the test password is not stored anywhere in Vault (marker included)');

    -- Duplicate protection
    begin perform set_config('purple.seed_target', target, true); execute seed; res := res || 'G14|false|second run was not refused';
    exception when others then res := res || ('G14|' || (sqlerrm like 'seed refused: this database is already seeded (completion marker%')::text || '|' || left(sqlerrm, 160)); end;
    begin
      delete from vault.secrets where name = 'purple_seed_marker';
      perform set_config('purple.seed_target', target, true); execute seed;
      res := res || 'G15|false|seed data without a marker was not detected';
    exception when others then res := res || ('G15|' || (sqlerrm like 'seed refused: % seed rows already exist without a completion marker%')::text || '|partial/legacy: ' || sqlerrm); end;
    begin
      execute wipe;
      insert into auth.users (instance_id, id, aud, role, email)
      values ('00000000-0000-0000-0000-000000000000', '97d27a6b-386a-886c-c532-3848a47852c8', 'authenticated', 'authenticated', 'leftover@seed.purple.test');
      perform set_config('purple.seed_target', target, true); execute seed;
      res := res || 'G15b|false|a single leftover seed-ID row was not detected';
    exception when others then res := res || ('G15b|' || (sqlerrm like 'seed refused: % seed rows already exist%')::text || '|single leftover seed-ID account: ' || sqlerrm); end;

    raise exception using errcode = 'P0W64', message = 'w6 guard tests rollback';
  exception when sqlstate 'P0W64' then null;
  end;

  insert into w6_results (suite, name, ok, detail)
  select 'seed_guard', split_part(r, '|', 1), split_part(r, '|', 2)::boolean,
         substr(r, length(split_part(r, '|', 1)) + length(split_part(r, '|', 2)) + 3) from unnest(res) r;
end $test$;
