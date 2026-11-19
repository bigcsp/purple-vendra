-- =====================================================================
-- Staging data backup (W6 seed replacement safeguard). STAGING ONLY.
--
-- Copies every non-empty table in public, private, auth and storage, plus
-- vault.secrets (encrypted, never decrypted) and cron.job, into one new,
-- private schema, and verifies each copy against its source (row count and
-- md5 of all rows). Read-only for existing data; it only ADDS a schema.
-- The schema is not exposed to the API and grants nothing to anyone.
--
--   set purple.backup_target = 'fwyviexwregngnqtwcra';
--   set purple.backup_schema = 'w6_backup_20261119';
--   \i supabase/tools/seed/backup_staging_data.sql
--
-- Restore notes: docs/W6-SEED-AND-ANONYMIZER.md §5.
-- =====================================================================
do $backup$
declare
  c_prod_ref     constant text   := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  v_target text := nullif(btrim(coalesce(current_setting('purple.backup_target', true), '')), '');
  v_schema text := nullif(btrim(coalesce(current_setting('purple.backup_schema', true), '')), '');
  v_url text; r record; v_rows bigint; v_src text; v_dst text; v_bad int;
begin
  if v_target is null or v_schema is null or v_schema !~ '^w6_backup_[0-9]{8}$' then
    raise exception 'backup refused: set purple.backup_target and purple.backup_schema (w6_backup_YYYYMMDD)';
  end if;
  select decrypted_secret into strict v_url from vault.decrypted_secrets where name = 'project_url';
  if position(c_prod_ref in lower(v_url || v_target)) > 0 or not (v_target = any (c_staging_refs))
     or v_url !~ ('^https://' || v_target || '\.supabase\.co/?$') then
    raise exception 'backup refused: not an approved staging project';
  end if;
  if exists (select 1 from pg_namespace where nspname = v_schema) then
    raise exception 'backup refused: schema % already exists', v_schema;
  end if;

  execute format('create schema %I', v_schema);
  execute format('revoke all on schema %I from public, anon, authenticated', v_schema);
  execute format('create table %I.manifest (source text primary key, backup_table text, rows bigint, source_md5 text, copy_md5 text, taken_at timestamptz default now())', v_schema);

  for r in select ns.nspname, cl.relname from pg_class cl join pg_namespace ns on ns.oid = cl.relnamespace
           where cl.relkind in ('r', 'p') and (ns.nspname in ('public', 'private', 'auth', 'storage')
                 or (ns.nspname = 'vault' and cl.relname = 'secrets') or (ns.nspname = 'cron' and cl.relname = 'job'))
           order by 1, 2 loop
    execute format('select count(*) from %I.%I', r.nspname, r.relname) into v_rows;
    continue when v_rows = 0;
    execute format('create table %I.%I as select * from %I.%I', v_schema, r.nspname || '__' || r.relname, r.nspname, r.relname);
    execute format('select md5(coalesce(string_agg(t::text, E''\n'' order by t::text), '''')) from %I.%I t', r.nspname, r.relname) into v_src;
    execute format('select md5(coalesce(string_agg(t::text, E''\n'' order by t::text), '''')) from %I.%I t', v_schema, r.nspname || '__' || r.relname) into v_dst;
    execute format('insert into %I.manifest (source, backup_table, rows, source_md5, copy_md5) values ($1, $2, $3, $4, $5)', v_schema)
      using r.nspname || '.' || r.relname, r.nspname || '__' || r.relname, v_rows, v_src, v_dst;
  end loop;

  execute format('select count(*) from %I.manifest where source_md5 is distinct from copy_md5', v_schema) into v_bad;
  if v_bad > 0 then
    raise exception 'backup failed verification: % tables differ (everything rolled back)', v_bad;
  end if;
  execute format('revoke all on all tables in schema %I from public, anon, authenticated', v_schema);
end $backup$;
