-- =====================================================================
-- 014 · Step 5: search, category browsing and professional profiles
-- ---------------------------------------------------------------------
-- * search_listings(): full-text + typo-tolerant (word similarity ≥ 0.45) title search over APPROVED
--   listings, with category / state / type / price filters and sorting.
--   SECURITY INVOKER, so the normal RLS rules decide what's visible.
-- * search_sellers(): find shops by business name, name, username or headline.
-- * log_search(): anonymous search log for weekly demand insights
--   (never stores who searched; 60 per minute site-wide cap per query text).
-- * working_hours + service_areas: public read for active sellers,
--   sellers manage their own (the 2FA + blocked-account rules from
--   006/009 already apply).
-- * Off-platform contact in a profile's headline/bio raises a flag.
-- =====================================================================

-- ---------- Working hours & service areas ----------------------------
create policy "Working hours of active sellers are public" on public.working_hours
  for select to anon, authenticated using (public.account_ok(seller_id));
create policy "Sellers set their own working hours" on public.working_hours
  for insert to authenticated with check (seller_id = (select auth.uid()));
create policy "Sellers change their own working hours" on public.working_hours
  for update to authenticated using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()));
create policy "Sellers remove their own working hours" on public.working_hours
  for delete to authenticated using (seller_id = (select auth.uid()));

create policy "Service areas of active sellers are public" on public.service_areas
  for select to anon, authenticated using (public.account_ok(seller_id));
create policy "Sellers add their own service areas" on public.service_areas
  for insert to authenticated with check (seller_id = (select auth.uid()));
create policy "Sellers remove their own service areas" on public.service_areas
  for delete to authenticated using (seller_id = (select auth.uid()));

alter table public.service_areas add constraint service_areas_city_len check (char_length(city) between 1 and 80);
create index if not exists service_areas_state on public.service_areas (state);

-- ---------- Search ----------------------------------------------------
create index if not exists listings_public_recent on public.listings (created_at desc) where status = 'approved';
create index if not exists profiles_business_trgm on public.profiles using gin (business_name gin_trgm_ops);
create index if not exists profiles_display_trgm on public.profiles using gin (display_name gin_trgm_ops);

create or replace function public.search_listings(
  p_query     text default null,
  p_category  smallint default null,
  p_state     text default null,
  p_type      public.listing_type default null,
  p_min_kobo  bigint default null,
  p_max_kobo  bigint default null,
  p_sort      text default 'relevance',   -- relevance | newest | price_low | price_high | rating
  p_limit     int default 24,
  p_offset    int default 0)
returns table (
  id uuid, title text, price_kobo bigint, price_is_starting boolean, quote_on_request boolean,
  type public.listing_type, category_id smallint, city text, state text, image_path text,
  seller_id uuid, seller_username text, seller_name text, seller_verified boolean,
  seller_rating numeric, seller_rating_count int, featured boolean, rank real, total_count bigint)
language sql stable security invoker set search_path = '' as $$
  with q as (
    select nullif(btrim(left(coalesce(p_query, ''), 200)), '') as text
  ),
  tsq as (
    select case when q.text is null then null else websearch_to_tsquery('english', q.text) end as query, q.text
    from q
  ),
  matches as (
    select l.*, p.username, coalesce(p.business_name, p.display_name) as sname, p.is_verified,
           p.rating_avg, p.rating_count,
           case
             when tsq.text is null then 0::real
             else ts_rank(l.search, tsq.query) + public.word_similarity(tsq.text, l.title)
           end as score
    from public.listings l
    join public.profiles p on p.id = l.seller_id
    cross join tsq
    where l.status = 'approved'
      and public.account_ok(l.seller_id)
      and (tsq.text is null or l.search @@ tsq.query or public.word_similarity(tsq.text, l.title) >= 0.45
           or l.title ilike '%' || tsq.text || '%')
      and (p_category is null or l.category_id = p_category)
      and (p_type is null or l.type = p_type)
      and (p_min_kobo is null or l.price_kobo >= p_min_kobo)
      and (p_max_kobo is null or l.price_kobo <= p_max_kobo)
      and (p_state is null or l.state = p_state
           or exists (select 1 from public.service_areas a where a.seller_id = l.seller_id and a.state = p_state))
  )
  select m.id, m.title, m.price_kobo, m.price_is_starting, m.quote_on_request, m.type, m.category_id,
         m.city, m.state,
         (select i.storage_path from public.listing_images i where i.listing_id = m.id order by i.position limit 1),
         m.seller_id, m.username, m.sname, m.is_verified, m.rating_avg, m.rating_count,
         (m.featured_until is not null and m.featured_until > now()),
         m.score, count(*) over ()
  from matches m
  order by
    (m.featured_until is not null and m.featured_until > now()) desc,
    case when p_sort = 'price_low' then m.price_kobo end asc nulls last,
    case when p_sort = 'price_high' then m.price_kobo end desc nulls last,
    case when p_sort = 'rating' then m.rating_avg end desc nulls last,
    case when p_sort = 'relevance' then m.score end desc nulls last,
    m.created_at desc
  limit least(greatest(p_limit, 1), 60) offset greatest(p_offset, 0);
$$;

create or replace function public.search_sellers(p_query text, p_limit int default 8)
returns table (id uuid, username text, name text, headline text, avatar_url text, city text, state text,
               is_verified boolean, rating_avg numeric, rating_count int, listings bigint)
language sql stable security invoker set search_path = '' as $$
  with q as (select nullif(btrim(left(coalesce(p_query, ''), 100)), '') as text)
  select p.id, p.username, coalesce(p.business_name, p.display_name), p.headline, p.avatar_url, p.city, p.state,
         p.is_verified, p.rating_avg, p.rating_count,
         (select count(*) from public.listings l where l.seller_id = p.id and l.status = 'approved')
  from public.profiles p, q
  where q.text is not null and p.role = 'seller' and public.account_ok(p.id)
    and (p.business_name ilike '%' || q.text || '%' or p.display_name ilike '%' || q.text || '%'
         or p.username ilike '%' || q.text || '%' or p.headline ilike '%' || q.text || '%'
         or public.word_similarity(q.text, coalesce(p.business_name, '')) >= 0.45
         or public.word_similarity(q.text, p.display_name) >= 0.45)
  order by p.is_verified desc, greatest(public.similarity(coalesce(p.business_name, ''), q.text),
                                       public.similarity(p.display_name, q.text)) desc
  limit least(greatest(p_limit, 1), 20);
$$;

-- Anonymous demand log: what people search for and how many results they got.
create or replace function public.log_search(p_query text, p_category smallint, p_results int)
returns void language plpgsql security definer set search_path = '' as $$
declare cleaned text := lower(btrim(left(coalesce(p_query, ''), 200)));
begin
  if cleaned = '' then return; end if;
  -- Cheap flood guard: same text logged at most 60 times a minute.
  if (select count(*) from public.search_queries
      where query = cleaned and created_at > now() - interval '1 minute') >= 60 then
    return;
  end if;
  insert into public.search_queries (query, category_id, results_count)
  values (cleaned, p_category, greatest(coalesce(p_results, 0), 0));
end $$;

-- ---------- Profile text safety --------------------------------------
create or replace function public.check_profile_risk()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.role in ('seller', 'admin')
     and public.looks_like_off_platform(coalesce(new.headline, '') || ' ' || coalesce(new.bio, '') || ' ' || coalesce(new.business_name, '')) then
    perform public.raise_flag('off_platform_contact', 'medium', new.id, null, 'profile', new.id::text,
      jsonb_build_object('headline', left(new.headline, 80)));
  end if;
  return null;
end $$;
create trigger profiles_risk_check after update of headline, bio, business_name on public.profiles
  for each row execute function public.check_profile_risk();

revoke execute on function public.check_profile_risk() from public, anon, authenticated;
revoke execute on function public.log_search(text, smallint, int) from public;
grant execute on function public.search_listings(text, smallint, text, public.listing_type, bigint, bigint, text, int, int),
  public.search_sellers(text, int), public.log_search(text, smallint, int) to anon, authenticated;
