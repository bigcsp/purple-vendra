-- =====================================================================
-- 019 · Saved items
--   * People can save approved listings (not their own) and see only
--     their own saved list. Max 500 saves per person.
--   * Sellers see how many people saved each of their listings, never who.
-- =====================================================================

create policy "You can see your saved items" on public.saves
  for select to authenticated using (user_id = (select auth.uid()));

create policy "You can save live listings" on public.saves
  for insert to authenticated with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.listings l
                where l.id = listing_id and l.status = 'approved' and l.seller_id <> (select auth.uid())));

create policy "You can unsave your items" on public.saves
  for delete to authenticated using (user_id = (select auth.uid()));

revoke all on public.saves from anon;
revoke update, truncate, references, trigger on public.saves from authenticated;
grant select, insert, delete on public.saves to authenticated;

create or replace function public.limit_saves()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.saves s where s.user_id = new.user_id) >= 500 then
    raise exception 'You can save up to 500 items. Remove some to save more.' using errcode = '54000';
  end if;
  return new;
end $$;
create trigger saves_limit before insert on public.saves
  for each row execute function public.limit_saves();

-- Seller insight: how many people saved each of your listings (anonymous).
create or replace function public.my_listing_save_counts()
returns table (listing_id uuid, saves bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select s.listing_id, count(*)
  from public.saves s
  join public.listings l on l.id = s.listing_id
  where l.seller_id = auth.uid()
  group by s.listing_id;
$$;
revoke execute on function public.my_listing_save_counts() from public, anon;
grant execute on function public.my_listing_save_counts() to authenticated;
