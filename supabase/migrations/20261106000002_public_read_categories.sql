-- Purple Vendra — let anyone (signed in or not) read the category list.
-- Categories are public information shown on the homepage.
-- Writes are still blocked for everyone except via the dashboard / admin tools.

create policy "Categories are public"
  on public.categories
  for select
  to anon, authenticated
  using (true);
