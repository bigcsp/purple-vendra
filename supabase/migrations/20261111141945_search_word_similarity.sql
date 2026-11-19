-- Production migration 20261111141945 search_word_similarity: production's recorded SQL, verbatim.
-- Source: supabase_migrations.schema_migrations.statements (read-only, 2026-11-19).
-- md5 of the SQL below this 4-line header (no trailing newline): 77b98d3fb6b696bee5dc731be02ea684
-- Replaces part of former repo file 014; commented original: docs/legacy/migrations-pre-c1/20261111000014_search_profiles.sql (C1, approved 2026-11-19).
create or replace function public.search_listings(
  p_query     text default null,
  p_category  smallint default null,
  p_state     text default null,
  p_type      public.listing_type default null,
  p_min_kobo  bigint default null,
  p_max_kobo  bigint default null,
  p_sort      text default 'relevance',
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
      and (tsq.text is null or l.search @@ tsq.query or tsq.text operator(public.<%) l.title
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
         or q.text operator(public.<%) coalesce(p.business_name, '') or q.text operator(public.<%) p.display_name)
  order by p.is_verified desc, greatest(public.similarity(coalesce(p.business_name, ''), q.text),
                                       public.similarity(p.display_name, q.text)) desc
  limit least(greatest(p_limit, 1), 20);
$$;
