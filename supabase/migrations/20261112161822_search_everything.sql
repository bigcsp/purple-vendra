-- =====================================================================
-- 018 · Search for anything
--   * search_synonyms: groups of words that mean the same thing
--     (aso ebi / asoebi, plumber / plumbing, mua / makeup artist …)
--   * search_terms_for(q): the synonyms a query should also match
--   * search_listings / search_sellers now understand synonyms
--   * search_stories: find Purple Stories by words, seller or synonym
--   * search_suggest: instant suggestions while typing (all kinds)
--   * popular_searches: what many people searched (anonymous, 2+ times)
--   * search_did_you_mean: spelling help when nothing matches
-- =====================================================================

create table if not exists public.search_synonyms (
  id            smallserial primary key,
  words         text[] not null check (cardinality(words) between 2 and 20),
  category_slug text references public.categories(slug) on update cascade on delete set null
);
alter table public.search_synonyms enable row level security;
create policy "Anyone can read search synonyms" on public.search_synonyms for select using (true);
revoke insert, update, delete, truncate on public.search_synonyms from anon, authenticated;

insert into public.search_synonyms (words, category_slug) values
  (array['aso ebi','asoebi','aso-ebi','family cloth','uniform fabric'], 'fashion-adire'),
  (array['ankara','ankara print','wax print','african print','kitenge','chitenge'], 'fashion-adire'),
  (array['adire','tie and dye','tie dye','tie-dye','kampala','batik'], 'fashion-adire'),
  (array['agbada','babariga','grand boubou','big gown'], 'fashion-adire'),
  (array['kaftan','caftan','senator','senator wear','jalabiya'], 'fashion-adire'),
  (array['aso oke','asooke','aso-oke'], 'fashion-adire'),
  (array['gele','headtie','head tie','head wrap','headwrap'], 'fashion-adire'),
  (array['buba','iro','iro and buba','wrapper'], 'fashion-adire'),
  (array['tailor','seamstress','fashion designer','sewing','bespoke'], 'fashion-adire'),
  (array['shoe','shoes','footwear','sandals','slippers','palm','palms','sneakers'], 'fashion-adire'),
  (array['bag','bags','handbag','purse','tote'], 'fashion-adire'),
  (array['jewelry','jewellery','beads','necklace','bracelet','earrings','waist beads'], 'fashion-adire'),
  (array['painting','paintings','artwork','art','canvas','portrait'], 'art-crafts'),
  (array['sculpture','carving','wood carving','bronze'], 'art-crafts'),
  (array['logo','logo design','branding','brand identity','graphic design','graphics','flyer','flier'], 'digital-design'),
  (array['ui','ux','ui ux','product design','app design'], 'digital-design'),
  (array['photographer','photography','photoshoot','photo shoot','pictures','shoot'], 'photo-video-talent'),
  (array['videographer','videography','video','video coverage','cinematographer','drone'], 'photo-video-talent'),
  (array['makeup','make up','mua','makeup artist','beat','glam'], 'photo-video-talent'),
  (array['model','models','modelling','modeling','brand ambassador'], 'photo-video-talent'),
  (array['dj','disc jockey','deejay'], 'photo-video-talent'),
  (array['mc','compere','hype man','host'], 'photo-video-talent'),
  (array['hair','hairstylist','hair stylist','braids','braiding','wig','wigs','weave','barber','haircut'], 'photo-video-talent'),
  (array['website','web design','web developer','web development','site','landing page','wordpress'], 'tech-freelance'),
  (array['app','mobile app','app developer','android','ios','flutter'], 'tech-freelance'),
  (array['developer','programmer','software','coder','software engineer'], 'tech-freelance'),
  (array['social media','social media manager','smm','content creator','content creation'], 'tech-freelance'),
  (array['writer','copywriter','copywriting','content writer','writing','cv','resume'], 'tech-freelance'),
  (array['plumber','plumbing','pipe','pipes','leak','leaking','water heater','borehole'], 'home-services'),
  (array['electrician','electrical','wiring','rewiring','inverter','solar','solar panel'], 'home-services'),
  (array['ac','a/c','air conditioner','aircon','ac repair','air conditioning','fridge repair'], 'home-services'),
  (array['generator','gen','generator repair','gen repair','mechanic'], 'home-services'),
  (array['carpenter','carpentry','furniture','wardrobe','kitchen cabinet','cabinets'], 'home-services'),
  (array['painter','house painting','screeding','pop ceiling','pop','wall painting'], 'home-services'),
  (array['cleaner','cleaning','house cleaning','deep cleaning','fumigation','pest control'], 'home-services'),
  (array['laundry','dry cleaning','dry cleaner','washing','ironing'], 'home-services'),
  (array['tiler','tiling','tiles','bricklayer','mason','builder'], 'home-services'),
  (array['caterer','catering','small chops','food','chef','cook','jollof'], null),
  (array['cake','cakes','baker','baking','cupcakes','pastries'], null),
  (array['event planner','event planning','decorator','decoration','decor','event decor'], null),
  (array['tutor','tutoring','lessons','teacher','home lesson','coaching'], null)
on conflict do nothing;

-- Search-friendly form of text: lowercase, letters and digits only.
create or replace function public.search_norm(t text)
returns text
language sql
immutable
set search_path = ''
as $$ select btrim(regexp_replace(lower(coalesce(t, '')), '[^a-z0-9]+', ' ', 'g')); $$;

-- Every synonym a query should also match (includes words from the query's groups).
create or replace function public.search_terms_for(q text)
returns text[]
language sql
stable
set search_path = ''
as $$
  select coalesce(array_agg(distinct public.search_norm(w)), '{}')
  from public.search_synonyms g
  cross join lateral unnest(g.words) w
  where ' ' || public.search_norm(q) || ' ' like any (
          select '% ' || public.search_norm(x) || ' %' from unnest(g.words) x)
    and public.search_norm(w) <> public.search_norm(q);
$$;

-- ---------------------------------------------------------------------
-- Listings: same signature as before, now with synonyms.
-- ---------------------------------------------------------------------
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
  terms as (
    select q.text, case when q.text is null then '{}'::text[] else public.search_terms_for(q.text) end as syn
    from q
  ),
  tsq as (
    select t.text, t.syn,
           case when t.text is null then null
                else websearch_to_tsquery('english',
                       t.text || coalesce((select string_agg(' or "' || replace(s, '"', '') || '"', '') from unnest(t.syn) s), ''))
           end as query
    from terms t
  ),
  matches as (
    select l.*, p.username, coalesce(p.business_name, p.display_name) as sname, p.is_verified,
           p.rating_avg, p.rating_count,
           case
             when tsq.text is null then 0::real
             else ts_rank(l.search, tsq.query) + public.word_similarity(tsq.text, l.title)
                  + case when l.title ilike '%' || tsq.text || '%' then 0.5 else 0 end
           end as score
    from public.listings l
    join public.profiles p on p.id = l.seller_id
    cross join tsq
    where l.status = 'approved'
      and public.account_ok(l.seller_id)
      and (tsq.text is null
           or l.search @@ tsq.query
           or public.word_similarity(tsq.text, l.title) >= 0.45
           or l.title ilike '%' || tsq.text || '%'
           or exists (select 1 from unnest(tsq.syn) s where l.title ilike '%' || s || '%'))
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
  with q as (select nullif(btrim(left(coalesce(p_query, ''), 100)), '') as text),
  t as (select q.text, case when q.text is null then '{}'::text[] else public.search_terms_for(q.text) end as syn from q)
  select p.id, p.username, coalesce(p.business_name, p.display_name), p.headline, p.avatar_url, p.city, p.state,
         p.is_verified, p.rating_avg, p.rating_count,
         (select count(*) from public.listings l where l.seller_id = p.id and l.status = 'approved')
  from public.profiles p, t
  where t.text is not null and p.role = 'seller' and public.account_ok(p.id)
    and (p.business_name ilike '%' || t.text || '%' or p.display_name ilike '%' || t.text || '%'
         or p.username ilike '%' || t.text || '%' or p.headline ilike '%' || t.text || '%'
         or public.word_similarity(t.text, coalesce(p.business_name, '')) >= 0.45
         or public.word_similarity(t.text, p.display_name) >= 0.45
         or exists (select 1 from unnest(t.syn) s
                    where p.headline ilike '%' || s || '%' or p.business_name ilike '%' || s || '%'))
  order by p.is_verified desc,
           greatest(public.similarity(coalesce(p.business_name, ''), t.text), public.similarity(p.display_name, t.text)) desc,
           p.rating_count desc
  limit least(greatest(p_limit, 1), 20);
$$;

-- ---------------------------------------------------------------------
-- Stories by words (same row shape as get_story_feed's key fields).
-- ---------------------------------------------------------------------
create or replace function public.search_stories(p_query text, p_limit int default 12)
returns table (video_id uuid, seller_id uuid, seller_username text, seller_name text,
               seller_verified boolean, campaign_id uuid)
language sql stable security definer set search_path = '' as $$
  with q as (select nullif(btrim(left(coalesce(p_query, ''), 100)), '') as text),
  t as (select q.text, case when q.text is null then '{}'::text[] else public.search_terms_for(q.text) end as syn from q)
  select v.id, v.seller_id, p.username, coalesce(p.business_name, p.display_name), p.is_verified, null::uuid
  from public.story_videos v
  join public.profiles p on p.id = v.seller_id
  cross join t
  where t.text is not null and v.status = 'published' and public.account_ok(v.seller_id)
    and (v.title ilike '%' || t.text || '%' or v.description ilike '%' || t.text || '%'
         or public.word_similarity(t.text, v.title) >= 0.45
         or coalesce(p.business_name, p.display_name) ilike '%' || t.text || '%'
         or exists (select 1 from unnest(t.syn) s where v.title ilike '%' || s || '%' or v.description ilike '%' || s || '%'))
  order by public.word_similarity(t.text, v.title) desc, v.published_at desc
  limit least(greatest(p_limit, 1), 24);
$$;

-- ---------------------------------------------------------------------
-- Popular searches: only queries searched at least twice, that found
-- something, and contain no contact details. Never says who searched.
-- ---------------------------------------------------------------------
create or replace function public.popular_searches(p_prefix text default null, p_limit int default 8)
returns table (query text, searches bigint)
language sql stable security definer set search_path = '' as $$
  select public.search_norm(s.query) as q, count(*)
  from public.search_queries s
  where s.created_at > now() - interval '60 days'
    and s.results_count > 0
    and char_length(public.search_norm(s.query)) between 2 and 40
    and public.contact_problem(s.query) is null
    and (p_prefix is null or public.search_norm(s.query) like public.search_norm(p_prefix) || '%')
  group by 1
  having count(*) >= 2
  order by 2 desc, 1
  limit least(greatest(p_limit, 1), 20);
$$;

-- ---------------------------------------------------------------------
-- Instant suggestions while typing.
-- kind: search | category | shop | listing | story
-- ---------------------------------------------------------------------
create or replace function public.search_suggest(p_query text, p_limit int default 10)
returns table (kind text, label text, detail text, slug text, image text, verified boolean)
language sql stable security definer set search_path = '' as $$
  with q as (select public.search_norm(left(coalesce(p_query, ''), 60)) as text),
  t as (select q.text, case when char_length(q.text) < 2 then '{}'::text[] else public.search_terms_for(q.text) end as syn from q),
  word_hits as (   -- synonym words that start with what was typed ("aso" → "aso ebi")
    select distinct public.search_norm(w) as w, g.category_slug
    from public.search_synonyms g cross join lateral unnest(g.words) w, t
    where char_length(t.text) >= 2 and public.search_norm(w) like t.text || '%'
  ),
  s_popular as (
    select 'search'::text as kind, ps.query as label, null::text as detail, null::text as slug, null::text as image,
           false as verified, 1 as grp, ps.searches::real as score
    from t, public.popular_searches(t.text, 3) ps
    where char_length(t.text) >= 2
  ),
  s_words as (
    select 'search'::text, w.w, null::text, null::text, null::text, false, 1, 0.5::real
    from word_hits w
    where not exists (select 1 from s_popular sp where sp.label = w.w)
    order by char_length(w.w) limit 2
  ),
  s_cat as (
    select 'category'::text, c.name, 'Category'::text, c.slug, null::text, false, 2,
           greatest(public.word_similarity(t.text, lower(c.name)), 0)::real
    from public.categories c, t
    where char_length(t.text) >= 2
      and (lower(c.name) like '%' || t.text || '%'
           or public.word_similarity(t.text, lower(c.name)) >= 0.5
           or c.slug in (select category_slug from word_hits where category_slug is not null)
           or c.slug in (select g.category_slug from public.search_synonyms g
                         where g.category_slug is not null
                           and exists (select 1 from unnest(g.words) x where public.search_norm(x) = any (t.syn))))
    order by 8 desc limit 2
  ),
  s_shop as (
    select 'shop'::text, coalesce(p.business_name, p.display_name), '@' || p.username, p.username, p.avatar_url, p.is_verified, 3,
           public.word_similarity(t.text, lower(coalesce(p.business_name, p.display_name)))::real
    from public.profiles p, t
    where char_length(t.text) >= 2 and p.role = 'seller' and public.account_ok(p.id)
      and (lower(coalesce(p.business_name, '')) like '%' || t.text || '%'
           or lower(p.display_name) like '%' || t.text || '%'
           or p.username like '%' || replace(t.text, ' ', '') || '%'
           or public.word_similarity(t.text, lower(coalesce(p.business_name, p.display_name))) >= 0.5)
    order by p.is_verified desc, 8 desc limit 3
  ),
  s_listing as (
    select 'listing'::text, l.title, coalesce(p.business_name, p.display_name), l.id::text,
           (select i.storage_path from public.listing_images i where i.listing_id = l.id order by i.position limit 1),
           p.is_verified, 4,
           (public.word_similarity(t.text, lower(l.title)) + case when lower(l.title) like t.text || '%' then 1 else 0 end)::real
    from public.listings l join public.profiles p on p.id = l.seller_id, t
    where char_length(t.text) >= 2 and l.status = 'approved' and public.account_ok(l.seller_id)
      and (lower(l.title) like '%' || t.text || '%'
           or public.word_similarity(t.text, lower(l.title)) >= 0.5
           or exists (select 1 from unnest(t.syn) s where lower(l.title) like '%' || s || '%'))
    order by 8 desc, l.created_at desc limit 4
  ),
  s_story as (
    select 'story'::text, v.title, coalesce(p.business_name, p.display_name), v.id::text, v.thumbnail_path, p.is_verified, 5,
           public.word_similarity(t.text, lower(v.title))::real
    from public.story_videos v join public.profiles p on p.id = v.seller_id, t
    where char_length(t.text) >= 2 and v.status = 'published' and public.account_ok(v.seller_id)
      and (lower(v.title) like '%' || t.text || '%'
           or public.word_similarity(t.text, lower(v.title)) >= 0.5
           or exists (select 1 from unnest(t.syn) s where lower(v.title) like '%' || s || '%'))
    order by 8 desc, v.published_at desc limit 2
  ),
  everything as (
    select * from s_popular union all select * from s_words union all select * from s_cat
    union all select * from s_shop union all select * from s_listing union all select * from s_story
  )
  select e.kind, e.label, e.detail, e.slug, e.image, e.verified
  from everything e
  order by e.grp, e.score desc
  limit least(greatest(p_limit, 1), 16);
$$;

-- ---------------------------------------------------------------------
-- "Did you mean …?" when a search finds nothing.
-- ---------------------------------------------------------------------
create or replace function public.search_did_you_mean(p_query text)
returns text
language sql stable security definer set search_path = '' as $$
  with q as (select public.search_norm(left(coalesce(p_query, ''), 60)) as text),
  vocab as (
    select public.search_norm(w) as v from public.search_synonyms g cross join lateral unnest(g.words) w
    union select lower(c.name) from public.categories c
    union select public.search_norm(l.title) from public.listings l where l.status = 'approved'
    union select public.search_norm(coalesce(p.business_name, p.display_name)) from public.profiles p
          where p.role = 'seller' and public.account_ok(p.id)
    union select ps.query from public.popular_searches(null, 20) ps
  )
  select v.v
  from vocab v, q
  where char_length(q.text) >= 3 and v.v <> q.text
    and public.similarity(v.v, q.text) >= 0.3
  order by public.similarity(v.v, q.text) desc, char_length(v.v)
  limit 1;
$$;

revoke execute on function public.popular_searches(text, int), public.search_suggest(text, int),
  public.search_did_you_mean(text), public.search_stories(text, int) from public;
grant execute on function public.popular_searches(text, int), public.search_suggest(text, int),
  public.search_did_you_mean(text), public.search_stories(text, int), public.search_terms_for(text),
  public.search_norm(text) to anon, authenticated;
