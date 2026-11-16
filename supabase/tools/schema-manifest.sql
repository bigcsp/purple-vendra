-- =====================================================================
-- Purple Shop schema manifest (read-only, catalog metadata only)
-- ---------------------------------------------------------------------
-- Produces one row per database object we own, with a short fingerprint
-- (first 12 hex chars of md5) of its normalized definition. Run the SAME
-- query on production and staging and compare row by row.
--
-- Reads ONLY system catalogs (pg_catalog, pg_policies, storage.buckets
-- settings, cron.job definitions). It never selects application rows,
-- storage objects, users or messages.
--
-- Normalization (documented in docs/MIGRATION-MAPPING.md):
--   * grants compared as sorted (grantee, privilege) pairs; grantor ignored
--   * cron commands: project ref replaced with <ref>
--   * extension versions reported separately (allowed to differ)
--   * sequence current values never read
-- =====================================================================
with s as (
  select oid, nspname from pg_namespace where nspname in ('public', 'private')
),
own_fn as (   -- functions we created (not installed by an extension)
  select p.oid, s.nspname, p.proname,
         p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')' as ident
  from pg_proc p join s on s.oid = p.pronamespace
  where not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
),
fn_acl as (
  select f.oid,
         coalesce(string_agg(a.grantee_name || ':' || a.privilege_type, ',' order by a.grantee_name, a.privilege_type), '') as acl
  from own_fn f
  left join lateral (
    select case when x.grantee = 0 then 'PUBLIC' else pg_get_userbyid(x.grantee) end as grantee_name, x.privilege_type
    from aclexplode(coalesce((select proacl from pg_proc where oid = f.oid), acldefault('f', (select proowner from pg_proc where oid = f.oid)))) x
  ) a on true
  group by f.oid
),
tbl as (
  select c.oid, s.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity, c.relacl, c.relowner
  from pg_class c join s on s.oid = c.relnamespace
  where c.relkind in ('r', 'p')
),
tbl_parts as (
  select t.oid, t.nspname || '.' || t.relname as ident,
    (select string_agg(a.attname || ' ' || format_type(a.atttypid, a.atttypmod)
              || case when a.attnotnull then ' NN' else '' end
              || coalesce(' D:' || pg_get_expr(ad.adbin, ad.adrelid), '')
              || case when a.attidentity <> '' then ' ID:' || a.attidentity::text else '' end
              || case when a.attgenerated <> '' then ' G' else '' end,
            ' | ' order by a.attnum)
     from pg_attribute a left join pg_attrdef ad on ad.adrelid = a.attrelid and ad.adnum = a.attnum
     where a.attrelid = t.oid and a.attnum > 0 and not a.attisdropped) as cols,
    (select string_agg(co.conname || ' ' || pg_get_constraintdef(co.oid), ' | ' order by co.conname)
     from pg_constraint co where co.conrelid = t.oid) as cons,
    (select string_agg(pg_get_indexdef(i.indexrelid), ' | ' order by pg_get_indexdef(i.indexrelid))
     from pg_index i where i.indrelid = t.oid) as idx,
    (select string_agg(pg_get_triggerdef(tg.oid), ' | ' order by tg.tgname)
     from pg_trigger tg where tg.tgrelid = t.oid and not tg.tgisinternal) as trg,
    'rls=' || t.relrowsecurity || ' force=' || t.relforcerowsecurity as rls,
    (select string_agg(case when x.grantee = 0 then 'PUBLIC' else pg_get_userbyid(x.grantee) end || ':' || x.privilege_type, ','
                       order by 1)
     from aclexplode(coalesce(t.relacl, acldefault('r', t.relowner))) x) as acl
  from tbl t
)
select kind, ident, h from (
  -- functions: definition + grants
  select 'function' as kind, f.nspname || '.' || f.ident as ident,
         left(md5(pg_get_functiondef(f.oid)), 12) || '/' || left(md5(a.acl), 6) as h
  from own_fn f join fn_acl a on a.oid = f.oid
  union all
  -- tables: columns / constraints / indexes / triggers / rls / grants (separate fingerprints)
  select 'table', ident,
         left(md5(coalesce(cols, '')), 8) || '.' || left(md5(coalesce(cons, '')), 6) || '.' ||
         left(md5(coalesce(idx, '')), 6) || '.' || left(md5(coalesce(trg, '')), 6) || '.' ||
         left(md5(rls), 4) || '.' || left(md5(coalesce(acl, '')), 6)
  from tbl_parts
  union all
  -- triggers we own on tables OUTSIDE public/private (e.g. auth.users, storage.objects)
  select 'ext_trigger', n.nspname || '.' || c.relname || '.' || tg.tgname, left(md5(pg_get_triggerdef(tg.oid)), 12)
  from pg_trigger tg join pg_class c on c.oid = tg.tgrelid join pg_namespace n on n.oid = c.relnamespace
  join pg_proc p on p.oid = tg.tgfoid join s on s.oid = p.pronamespace
  where not tg.tgisinternal and n.nspname not in ('public', 'private')
  union all
  -- RLS policies (public, private, storage)
  select 'policy', schemaname || '.' || tablename || '.' || policyname,
         left(md5(cmd || '|' || permissive || '|' || array_to_string(array(select unnest(roles) order by 1), ',') || '|' ||
                  coalesce(qual, '') || '|' || coalesce(with_check, '')), 12)
  from pg_policies where schemaname in ('public', 'private', 'storage')
  union all
  -- enum / domain / composite types
  select 'type', n.nspname || '.' || t.typname,
         left(md5(coalesce(
           (select string_agg(e.enumlabel, ',' order by e.enumsortorder) from pg_enum e where e.enumtypid = t.oid),
           format_type(t.typbasetype, t.typtypmod) || coalesce(t.typdefault, ''),
           (select string_agg(a.attname || ' ' || format_type(a.atttypid, a.atttypmod), ',' order by a.attnum)
              from pg_attribute a where a.attrelid = t.typrelid and a.attnum > 0))), 12)
  from pg_type t join pg_namespace n on n.oid = t.typnamespace join s on s.oid = n.oid
  where t.typtype in ('e', 'd') or (t.typtype = 'c' and exists (select 1 from pg_class c where c.oid = t.typrelid and c.relkind = 'c'))
  union all
  -- sequences (definition only, never current value)
  select 'sequence', n.nspname || '.' || c.relname,
         left(md5(sq.seqtypid::regtype::text || sq.seqincrement || sq.seqmin || sq.seqmax || sq.seqcycle), 12)
  from pg_class c join pg_namespace n on n.oid = c.relnamespace join s on s.oid = n.oid
  join pg_sequence sq on sq.seqrelid = c.oid
  where c.relkind = 'S'
  union all
  -- storage bucket configuration (not contents)
  select 'bucket', id,
         left(md5(public::text || '|' || coalesce(file_size_limit::text, '') || '|' ||
                  coalesce(array_to_string(array(select unnest(allowed_mime_types) order by 1), ','), '')), 12)
  from storage.buckets
  union all
  -- cron jobs, project ref normalized
  select 'cron', jobname,
         left(md5(schedule || '|' || regexp_replace(regexp_replace(command, 'https://[a-z0-9]+\.supabase\.co', 'https://<ref>.supabase.co', 'g'), '\s+', ' ', 'g')), 12)
  from cron.job
  union all
  -- extensions: schema only (version reported separately as allowed difference)
  select 'extension', e.extname, n.nspname
  from pg_extension e join pg_namespace n on n.oid = e.extnamespace
  union all
  select 'extension_version', e.extname, e.extversion from pg_extension e
) m
order by kind, ident;
