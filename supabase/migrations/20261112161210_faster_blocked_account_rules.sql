-- 017 · Speed: the "Blocked accounts cannot insert/update/delete" rules
-- re-checked the account for every row. Wrapping auth.uid() in its own
-- select makes Postgres check it once per request. Same rule, faster.
do $$
declare
  p record;
  expr text := '(select public.account_ok((select auth.uid())))';
begin
  for p in
    select schemaname, tablename, policyname, cmd
    from pg_policies
    where schemaname = 'public' and policyname like 'Blocked accounts cannot %'
  loop
    if p.cmd = 'INSERT' then
      execute format('alter policy %I on %I.%I with check (%s)', p.policyname, p.schemaname, p.tablename, expr);
    elsif p.cmd = 'UPDATE' then
      execute format('alter policy %I on %I.%I using (%s) with check (%s)', p.policyname, p.schemaname, p.tablename, expr, expr);
    else
      execute format('alter policy %I on %I.%I using (%s)', p.policyname, p.schemaname, p.tablename, expr);
    end if;
  end loop;
end $$;
