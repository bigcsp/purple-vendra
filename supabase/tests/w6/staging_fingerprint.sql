-- =====================================================================
-- Staging fingerprint (read-only). Snapshot evidence for W6 test runs.
-- Run before and after any test that changes data inside a rolled-back
-- block; the two outputs must be identical.
--
-- Per table: row count + md5 of all rows (sorted). Covers every table in
-- public, private, auth, storage, vault.secrets (encrypted values, never
-- decrypted) and cron.job. Plus one catalog checksum: functions, triggers
-- and their enabled state, policies, constraints.
-- Excluded on purpose (they change by themselves): cron.job_run_details,
-- the pg_net request/response tables, realtime.
-- =====================================================================
create temp table if not exists w6_fp (obj text primary key, rows bigint, digest text);
truncate w6_fp;

do $fp$
declare r record; v_rows bigint; v_md5 text;
begin
  for r in select ns.nspname, cl.relname from pg_class cl join pg_namespace ns on ns.oid = cl.relnamespace
           where cl.relkind in ('r', 'p') and (ns.nspname in ('public', 'private', 'auth', 'storage')
                 or (ns.nspname = 'vault' and cl.relname = 'secrets') or (ns.nspname = 'cron' and cl.relname = 'job'))
           order by 1, 2 loop
    execute format('select count(*), md5(coalesce(string_agg(t::text, E''\n'' order by t::text), '''')) from %I.%I t', r.nspname, r.relname)
      into v_rows, v_md5;
    insert into w6_fp values (r.nspname || '.' || r.relname, v_rows, v_md5);
  end loop;

  insert into w6_fp
  select 'catalog: functions, triggers (+enabled), policies, constraints', null, md5(
      coalesce((select string_agg(pg_get_functiondef(p.oid), E'\n' order by p.oid::regprocedure::text) from pg_proc p
                where p.pronamespace in ('public'::regnamespace, 'private'::regnamespace) and p.prokind in ('f', 'p')), '')
   || coalesce((select string_agg(t.tgrelid::regclass || ':' || pg_get_triggerdef(t.oid) || ':' || t.tgenabled::text, E'\n' order by 1) from pg_trigger t
                where not t.tgisinternal and t.tgrelid in (select oid from pg_class where relnamespace in ('public'::regnamespace, 'private'::regnamespace, 'storage'::regnamespace, 'auth'::regnamespace))), '')
   || coalesce((select string_agg(schemaname || '.' || tablename || '.' || policyname || ':' || coalesce(qual, '') || ':' || coalesce(with_check, ''), E'\n' order by 1) from pg_policies), '')
   || coalesce((select string_agg(conrelid::regclass || ':' || conname || ':' || pg_get_constraintdef(oid), E'\n' order by 1) from pg_constraint
                where connamespace in ('public'::regnamespace, 'private'::regnamespace)), ''));
end $fp$;

select obj, rows, digest from w6_fp
union all
select '== ALL (combined)', sum(rows), md5(string_agg(obj || '|' || coalesce(rows::text, '') || '|' || digest, E'\n' order by obj)) from w6_fp
order by 1;
