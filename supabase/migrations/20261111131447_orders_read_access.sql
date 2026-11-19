-- 013 · Read access to orders (needed by the seller Orders page).
-- Sellers see orders for their shop, buyers see their own, admins see all.
-- Read-only: creating and changing orders comes with checkout (step 7).
create policy "Sellers see their own orders" on public.orders
  for select to authenticated using (seller_id = (select auth.uid()));
create policy "Buyers see their own orders" on public.orders
  for select to authenticated using (buyer_id = (select auth.uid()));
create policy "Admins see all orders" on public.orders
  for select to authenticated using ((select public.is_admin()));
create policy "Order items follow their order" on public.order_items
  for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_items.order_id
                 and (o.seller_id = (select auth.uid()) or o.buyer_id = (select auth.uid()) or (select public.is_admin()))));
