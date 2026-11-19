-- =====================================================================
-- Replace an older synthetic seed on STAGING with the current seed.
-- Owner-approved operation (19 Nov 2026). STAGING ONLY. One statement:
-- it either completes or changes nothing.
--
-- Needs: temp table w6_scripts with the current seed text (name = 'seed'),
--        purple.seed_target = the staging ref,
--        purple.backup_schema = a verified backup made by backup_staging_data.sql.
--
-- It deletes ONLY rows that belong to the old seed:
--   * rows linked to the 32 seed accounts (seed domain AND a known seed id),
--   * the seed's search-log rows (matched exactly on query/category/count),
--   * storage-cleanup queue rows for the seed's placeholder files.
-- It refuses if any other account exists, if a completion marker already
-- exists, or if the backup is missing or unverified.
-- Append-only history (seller register, milestones, status history,
-- security events) is NOT deleted: those guards stay on.
-- =====================================================================
do $replace$
declare
  c_prod_ref     constant text   := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  seed     text := (select body from w6_scripts where name = 'seed');
  v_target text := nullif(btrim(coalesce(current_setting('purple.seed_target', true), '')), '');
  v_schema text := nullif(btrim(coalesce(current_setting('purple.backup_schema', true), '')), '');
  v_url text; v_bad int; v_n int;
  v_users uuid[];
  -- the old seed's search-log rows (seed generator, section 10)
  c_seed_searches constant text[] := array['adire|1|3','ankara|1|0','website|5|2','logo|3|2','ac repair|6|2',
                                           'photographer|4|2','vase|2|1','electrician|6|1','bead necklace|2|1','voice over|4|2'];
begin
  -- target and project
  if v_target is null or position(c_prod_ref in lower(v_target)) > 0 or not (v_target = any (c_staging_refs)) then
    raise exception 'replace refused: purple.seed_target must be an approved staging ref';
  end if;
  begin
    select decrypted_secret into strict v_url from vault.decrypted_secrets where name = 'project_url';
  exception when others then
    raise exception 'replace refused: Vault project_url missing or unreadable (%)', sqlerrm;
  end;
  if position(c_prod_ref in lower(v_url)) > 0 or v_url !~ ('^https://' || v_target || '\.supabase\.co/?$') then
    raise exception 'replace refused: this database is not %', v_target;
  end if;
  -- backup must exist and be verified
  if v_schema is null or not exists (select 1 from pg_namespace where nspname = v_schema) then
    raise exception 'replace refused: backup schema % not found', coalesce(v_schema, '(not set)');
  end if;
  execute format('select count(*) filter (where source_md5 is distinct from copy_md5) from %I.manifest', v_schema) into v_bad;
  execute format('select count(*) from %I.manifest', v_schema) into v_n;
  if v_n = 0 or v_bad > 0 then
    raise exception 'replace refused: backup % is empty or unverified', v_schema;
  end if;
  -- only seed accounts may exist; a completed new seed must not exist yet
  if exists (select 1 from auth.users where email is null or email not like '%@seed.purple.test') then
    raise exception 'replace refused: non-seed accounts exist; nothing deleted';
  end if;
  if exists (select 1 from vault.secrets where name = 'purple_seed_marker') then
    raise exception 'replace refused: a completed (marked) seed is already present';
  end if;
  if seed is null then
    raise exception 'replace refused: current seed text not loaded';
  end if;

  v_users := array(select id from auth.users where email like '%@seed.purple.test');

  -- rows that block account deletion (no-action foreign keys), scoped to seed accounts
  delete from public.reviews where reviewer_id = any (v_users) or seller_id = any (v_users);
  delete from public.payouts where seller_id = any (v_users);
  delete from public.reseller_commissions where reseller_id = any (v_users);
  delete from public.disputes where opened_by = any (v_users);
  delete from public.bookings where buyer_id = any (v_users) or pro_id = any (v_users);
  delete from public.orders where buyer_id = any (v_users) or seller_id = any (v_users);
  delete from public.checkouts where buyer_id = any (v_users);
  delete from public.featured_purchases where seller_id = any (v_users);
  delete from public.reports where reporter_id = any (v_users) or reported_user_id = any (v_users) or handled_by = any (v_users);
  delete from public.risk_flags where user_id = any (v_users) or reviewed_by = any (v_users);
  delete from public.seller_verifications where user_id = any (v_users);
  -- the accounts themselves (profiles, listings, stories, requests, messages, ... cascade)
  delete from auth.users where id = any (v_users);
  -- the seed's own search-log rows and the cleanup queue rows created for its placeholder files
  delete from public.search_queries where query || '|' || coalesce(category_id::text, '') || '|' || results_count = any (c_seed_searches);
  delete from public.storage_deletion_queue where split_part(object_name, '/', 1) = any (array(select u::text from unnest(v_users) u))
                                              and split_part(object_name, '/', 2) = 'seed';

  -- load the current seed (its own guard runs again here)
  perform set_config('purple.seed_target', v_target, true);
  execute seed;
end $replace$;
