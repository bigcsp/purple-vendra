-- =====================================================================
-- 020 · Purple Requests
-- Buyers post what they need; sellers send offers; the buyer accepts one,
-- which opens a private chat. Decisions (12 Nov): public board (buyer
-- anonymous), text only, max 10 live offers per request, 14-day expiry.
--
-- All writes go through functions below (tables are read-only to the API),
-- so every rule is enforced in one place.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------
alter table public.buyer_requests
  add column if not exists expires_at        timestamptz not null default (now() + interval '14 days'),
  add column if not exists offer_count       int not null default 0,
  add column if not exists accepted_offer_id uuid,
  add column if not exists closed_at         timestamptz,
  add column if not exists updated_at        timestamptz not null default now();

alter table public.buyer_requests
  add constraint buyer_requests_city_len check (city is null or char_length(city) <= 60),
  add constraint buyer_requests_budget_max check (budget_kobo is null or budget_kobo <= 100000000000);

alter table public.request_offers
  add column if not exists delivery_days int,
  add column if not exists listing_id    uuid references public.listings(id) on delete set null,
  add column if not exists updated_at    timestamptz not null default now();

alter table public.request_offers
  add constraint request_offers_delivery_days check (delivery_days is null or delivery_days between 1 and 365),
  add constraint request_offers_price_max check (price_kobo <= 100000000000);

alter table public.buyer_requests
  add constraint buyer_requests_accepted_offer_fk foreign key (accepted_offer_id)
  references public.request_offers(id) on delete set null;

create index if not exists buyer_requests_open on public.buyer_requests (created_at desc) where status = 'open';
create index if not exists buyer_requests_buyer on public.buyer_requests (buyer_id, created_at desc);
create index if not exists buyer_requests_category on public.buyer_requests (category_id) where status = 'open';
create index if not exists request_offers_seller on public.request_offers (seller_id, created_at desc);
create index if not exists buyer_requests_title_trgm on public.buyer_requests using gin (title public.gin_trgm_ops);

-- ---------------------------------------------------------------------
-- Read access: your own requests, your own offers, offers on your requests.
-- The public board and request pages use the functions further down,
-- which never reveal who the buyer is.
-- ---------------------------------------------------------------------
create policy "Buyers see their own requests" on public.buyer_requests
  for select to authenticated using (buyer_id = (select auth.uid()));
create policy "Sellers see their own offers" on public.request_offers
  for select to authenticated using (seller_id = (select auth.uid()));
create policy "Buyers see offers on their requests" on public.request_offers
  for select to authenticated using (exists (
    select 1 from public.buyer_requests r where r.id = request_id and r.buyer_id = (select auth.uid())));

revoke all on public.buyer_requests, public.request_offers from anon;
revoke insert, update, delete, truncate, references, trigger on public.buyer_requests, public.request_offers from authenticated;
grant select on public.buyer_requests, public.request_offers to authenticated;

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
-- Lives in a private schema that the website API can't call directly, so
-- nobody can look up who posted a request. Report checks still can.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.request_owner(p_request uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select buyer_id from public.buyer_requests where id = p_request;
$$;
revoke execute on function private.request_owner(uuid) from public, anon;
grant execute on function private.request_owner(uuid) to authenticated;

-- Live offers = sent or accepted (withdrawn/declined don't count toward the 10).
create or replace function public.refresh_offer_count(p_request uuid)
returns void language sql security definer set search_path = '' as $$
  update public.buyer_requests r
  set offer_count = (select count(*) from public.request_offers o
                     where o.request_id = r.id and o.status in ('sent', 'accepted')),
      updated_at = now()
  where r.id = p_request;
$$;
revoke execute on function public.refresh_offer_count(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Buyer: create, edit (until the first offer), close
-- ---------------------------------------------------------------------
create or replace function public.create_request(
  p_title text, p_description text, p_category smallint, p_budget_kobo bigint,
  p_state text, p_city text, p_deadline date)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  t text := btrim(coalesce(p_title, ''));
  d text := btrim(coalesce(p_description, ''));
  c text := nullif(btrim(coalesce(p_city, '')), '');
  rid uuid;
begin
  if uid is null then
    raise exception 'Please sign in to post a request' using errcode = '42501';
  end if;
  if not public.account_ok(uid) then
    raise exception 'Your account can''t post requests right now' using errcode = '42501';
  end if;
  if char_length(t) < 5 or char_length(t) > 120 then
    raise exception 'Give your request a short title (5 to 120 characters)' using errcode = '22023';
  end if;
  if char_length(d) < 15 or char_length(d) > 2000 then
    raise exception 'Describe what you need in 15 to 2,000 characters' using errcode = '22023';
  end if;
  if p_category is null or not exists (select 1 from public.categories where id = p_category) then
    raise exception 'Choose a category' using errcode = '22023';
  end if;
  if p_state is null or btrim(p_state) = '' then
    raise exception 'Choose a state' using errcode = '22023';
  end if;
  if p_budget_kobo is not null and (p_budget_kobo < 100 or p_budget_kobo > 100000000000) then
    raise exception 'Enter a budget between ₦1 and ₦1,000,000,000, or leave it empty' using errcode = '22023';
  end if;
  if p_deadline is not null and (p_deadline < current_date or p_deadline > current_date + 180) then
    raise exception 'The date you need it by must be within the next 6 months' using errcode = '22023';
  end if;
  perform public.forbid_contact(t || ' ' || d || ' ' || coalesce(c, ''));

  if (select count(*) from public.buyer_requests where buyer_id = uid and status = 'open') >= 5 then
    raise exception 'You can have 5 open requests at a time. Close one to post another.' using errcode = '54000';
  end if;
  if (select count(*) from public.buyer_requests where buyer_id = uid and created_at > now() - interval '24 hours') >= 10 then
    raise exception 'You''ve posted a lot of requests today. Please try again tomorrow.' using errcode = '54000';
  end if;

  insert into public.buyer_requests (buyer_id, category_id, title, description, budget_kobo, deadline, state, city, status, expires_at)
  values (uid, p_category, t, d, p_budget_kobo, p_deadline, btrim(p_state), c, 'open',
          least(now() + interval '14 days', coalesce((p_deadline + 1)::timestamptz, now() + interval '14 days')))
  returning id into rid;
  return rid;
end $$;

create or replace function public.update_request(
  p_request uuid, p_title text, p_description text, p_category smallint, p_budget_kobo bigint,
  p_state text, p_city text, p_deadline date)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  r public.buyer_requests;
  t text := btrim(coalesce(p_title, ''));
  d text := btrim(coalesce(p_description, ''));
  c text := nullif(btrim(coalesce(p_city, '')), '');
begin
  select * into r from public.buyer_requests where id = p_request and buyer_id = uid;
  if r.id is null then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if r.status <> 'open' then
    raise exception 'This request is closed' using errcode = '22023';
  end if;
  if r.offer_count > 0 then
    raise exception 'You can''t edit a request after offers arrive. Close it and post a new one instead.' using errcode = '22023';
  end if;
  if char_length(t) < 5 or char_length(t) > 120 or char_length(d) < 15 or char_length(d) > 2000 then
    raise exception 'Title 5–120 characters, description 15–2,000 characters' using errcode = '22023';
  end if;
  if p_budget_kobo is not null and (p_budget_kobo < 100 or p_budget_kobo > 100000000000) then
    raise exception 'Enter a valid budget or leave it empty' using errcode = '22023';
  end if;
  if p_deadline is not null and (p_deadline < current_date or p_deadline > current_date + 180) then
    raise exception 'The date you need it by must be within the next 6 months' using errcode = '22023';
  end if;
  perform public.forbid_contact(t || ' ' || d || ' ' || coalesce(c, ''));

  update public.buyer_requests
  set title = t, description = d, category_id = coalesce(p_category, category_id), budget_kobo = p_budget_kobo,
      state = coalesce(nullif(btrim(p_state), ''), state), city = c, deadline = p_deadline,
      expires_at = least(created_at + interval '14 days', coalesce((p_deadline + 1)::timestamptz, created_at + interval '14 days')),
      updated_at = now()
  where id = r.id;
end $$;

create or replace function public.close_request(p_request uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.buyer_requests
  set status = 'closed', closed_at = now(), updated_at = now()
  where id = p_request and buyer_id = auth.uid() and status = 'open';
  if not found then
    raise exception 'Request not found or already closed' using errcode = 'P0002';
  end if;
  -- Offers still waiting are politely declined.
  update public.request_offers set status = 'declined', updated_at = now()
  where request_id = p_request and status = 'sent';
end $$;

-- ---------------------------------------------------------------------
-- Seller: send / edit / withdraw an offer
-- ---------------------------------------------------------------------
create or replace function public.send_offer(
  p_request uuid, p_price_kobo bigint, p_delivery_days int, p_message text, p_listing uuid default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  r public.buyer_requests;
  existing public.request_offers;
  m text := btrim(coalesce(p_message, ''));
  oid uuid;
begin
  if uid is null then
    raise exception 'Please sign in to send an offer' using errcode = '42501';
  end if;
  if not public.current_role_is(array['seller', 'admin']::public.user_role[]) then
    raise exception 'Only sellers can send offers. Open your shop first.' using errcode = '42501';
  end if;
  if not public.can_post() then
    raise exception 'Turn on two-factor sign-in to send offers' using errcode = '42501';
  end if;

  select * into r from public.buyer_requests where id = p_request;
  if r.id is null or r.status <> 'open' or r.expires_at <= now() then
    raise exception 'This request is no longer taking offers' using errcode = 'P0002';
  end if;
  if r.buyer_id = uid then
    raise exception 'You can''t send an offer on your own request' using errcode = '42501';
  end if;
  if public.is_blocked_between(uid, r.buyer_id) then
    raise exception 'You can''t send an offer on this request' using errcode = '42501';
  end if;
  if r.category_id = (select id from public.categories where slug = 'home-services')
     and not exists (select 1 from public.seller_verifications v where v.user_id = uid and v.status = 'approved') then
    raise exception 'Home-service pros need an approved ID check before sending offers' using errcode = '42501';
  end if;

  if p_price_kobo is null or p_price_kobo < 100 or p_price_kobo > 100000000000 then
    raise exception 'Enter your price' using errcode = '22023';
  end if;
  if p_delivery_days is null or p_delivery_days < 1 or p_delivery_days > 365 then
    raise exception 'Say how many days it will take (1 to 365)' using errcode = '22023';
  end if;
  if char_length(m) < 10 or char_length(m) > 1000 then
    raise exception 'Write a short message to the buyer (10 to 1,000 characters)' using errcode = '22023';
  end if;
  perform public.forbid_contact(m);
  if p_listing is not null and not exists (
       select 1 from public.listings l where l.id = p_listing and l.seller_id = uid and l.status = 'approved') then
    raise exception 'Attach one of your live listings, or none' using errcode = '22023';
  end if;

  select * into existing from public.request_offers where request_id = r.id and seller_id = uid;

  if existing.id is not null and existing.status = 'accepted' then
    raise exception 'Your offer was already accepted' using errcode = '22023';
  end if;
  if existing.id is not null and existing.status = 'declined' then
    raise exception 'The buyer declined your offer on this request' using errcode = '22023';
  end if;

  -- New offer (or re-sending a withdrawn one) must fit under the cap of 10.
  if (existing.id is null or existing.status = 'withdrawn') and r.offer_count >= 10 then
    raise exception 'This request already has 10 offers' using errcode = '54000';
  end if;
  if existing.id is null and (select count(*) from public.request_offers
        where seller_id = uid and created_at > now() - interval '24 hours') >= 30 then
    raise exception 'You''ve sent 30 offers today. Please try again tomorrow.' using errcode = '54000';
  end if;

  if existing.id is null then
    insert into public.request_offers (request_id, seller_id, message, price_kobo, delivery_days, listing_id, status)
    values (r.id, uid, m, p_price_kobo, p_delivery_days, p_listing, 'sent')
    returning id into oid;
  else
    update public.request_offers
    set message = m, price_kobo = p_price_kobo, delivery_days = p_delivery_days, listing_id = p_listing,
        status = 'sent', updated_at = now()
    where id = existing.id
    returning id into oid;
  end if;

  perform public.refresh_offer_count(r.id);
  return oid;
end $$;

create or replace function public.withdraw_offer(p_offer uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare rid uuid;
begin
  update public.request_offers set status = 'withdrawn', updated_at = now()
  where id = p_offer and seller_id = auth.uid() and status = 'sent'
  returning request_id into rid;
  if rid is null then
    raise exception 'Offer not found or can''t be withdrawn' using errcode = 'P0002';
  end if;
  perform public.refresh_offer_count(rid);
end $$;

-- ---------------------------------------------------------------------
-- Buyer: decline one offer / accept one offer (opens a chat)
-- ---------------------------------------------------------------------
create or replace function public.decline_offer(p_offer uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare rid uuid;
begin
  update public.request_offers o set status = 'declined', updated_at = now()
  from public.buyer_requests r
  where o.id = p_offer and r.id = o.request_id and r.buyer_id = auth.uid() and o.status = 'sent'
  returning o.request_id into rid;
  if rid is null then
    raise exception 'Offer not found' using errcode = 'P0002';
  end if;
  perform public.refresh_offer_count(rid);
end $$;

create or replace function public.accept_offer(p_offer uuid)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  o public.request_offers;
  r public.buyer_requests;
  conv uuid;
begin
  select * into o from public.request_offers where id = p_offer;
  select * into r from public.buyer_requests where id = o.request_id;
  if o.id is null or r.buyer_id is distinct from uid then
    raise exception 'Offer not found' using errcode = 'P0002';
  end if;
  if not public.account_ok(uid) then
    raise exception 'Your account can''t do this right now' using errcode = '42501';
  end if;
  if r.status <> 'open' then
    raise exception 'This request is already closed' using errcode = '22023';
  end if;
  if o.status <> 'sent' then
    raise exception 'This offer is no longer available' using errcode = '22023';
  end if;
  if not public.account_ok(o.seller_id) or public.is_blocked_between(uid, o.seller_id) then
    raise exception 'This seller isn''t available any more' using errcode = '42501';
  end if;

  update public.request_offers set status = 'accepted', updated_at = now() where id = o.id;
  update public.request_offers set status = 'declined', updated_at = now()
  where request_id = r.id and id <> o.id and status = 'sent';
  update public.buyer_requests
  set status = 'closed', accepted_offer_id = o.id, closed_at = now(), updated_at = now()
  where id = r.id;
  perform public.refresh_offer_count(r.id);

  -- Open (or reuse) a private chat about this offer.
  select c.id into conv from public.conversations c where c.request_offer_id = o.id;
  if conv is null then
    insert into public.conversations (buyer_id, seller_id, listing_id, request_offer_id, last_message_at, buyer_read_at)
    values (uid, o.seller_id, o.listing_id, o.id, now(), now())
    returning id into conv;
  end if;
  insert into public.messages (conversation_id, sender_id, body)
  values (conv, uid, 'I accepted your offer for "' || r.title || '". Let''s agree the details here. Payment goes through Purple Shop escrow.');
  update public.conversations set last_message_at = now(), seller_archived = false where id = conv;
  return conv;
end $$;

-- ---------------------------------------------------------------------
-- Expiry (hourly)
-- ---------------------------------------------------------------------
create or replace function public.expire_requests()
returns int
language plpgsql security definer set search_path = '' as $$
declare n int;
begin
  with gone as (
    update public.buyer_requests set status = 'expired', closed_at = now(), updated_at = now()
    where status = 'open' and expires_at <= now()
    returning id
  )
  select count(*) into n from gone;
  update public.request_offers o set status = 'declined', updated_at = now()
  from public.buyer_requests r
  where r.id = o.request_id and r.status = 'expired' and o.status = 'sent';
  return n;
end $$;
revoke execute on function public.expire_requests() from public, anon, authenticated;

select cron.schedule('requests-expire', '23 * * * *', 'select public.expire_requests()');

-- ---------------------------------------------------------------------
-- Public board (no buyer identity)
-- ---------------------------------------------------------------------
create or replace function public.get_request_board(
  p_query text default null, p_category smallint default null, p_state text default null,
  p_matches boolean default false, p_limit int default 24, p_offset int default 0)
returns table (
  id uuid, title text, description text, category_id smallint, budget_kobo bigint, state text, city text,
  deadline date, created_at timestamptz, expires_at timestamptz, offer_count int, is_full boolean,
  you_offered boolean, total_count bigint)
language sql stable security definer set search_path = '' as $$
  with q as (select nullif(btrim(left(coalesce(p_query, ''), 100)), '') as text),
  t as (select q.text, case when q.text is null then '{}'::text[] else public.search_terms_for(q.text) end as syn from q),
  me as (
    select auth.uid() as uid,
           coalesce(array_agg(distinct l.category_id) filter (where l.id is not null), '{}') as cats,
           coalesce((select array_agg(distinct a.state) from public.service_areas a where a.seller_id = auth.uid()), '{}')
             || coalesce((select array[p.state] from public.profiles p where p.id = auth.uid() and p.state is not null), '{}') as states
    from (select 1) x
    left join public.listings l on l.seller_id = auth.uid() and l.status = 'approved'
  )
  select r.id, r.title, left(r.description, 280), r.category_id, r.budget_kobo, r.state, r.city, r.deadline,
         r.created_at, r.expires_at, r.offer_count, r.offer_count >= 10,
         exists (select 1 from public.request_offers o where o.request_id = r.id and o.seller_id = me.uid and o.status <> 'withdrawn'),
         count(*) over ()
  from public.buyer_requests r cross join t cross join me
  where r.status = 'open' and r.expires_at > now() and public.account_ok(r.buyer_id)
    and (me.uid is null or r.buyer_id <> me.uid)
    and (me.uid is null or not public.is_blocked_between(me.uid, r.buyer_id))
    and (p_category is null or r.category_id = p_category)
    and (p_state is null or r.state = p_state)
    and (not p_matches or (r.category_id = any (me.cats) and (cardinality(me.states) = 0 or r.state = any (me.states))))
    and (t.text is null
         or r.title ilike '%' || t.text || '%' or r.description ilike '%' || t.text || '%'
         or public.word_similarity(t.text, r.title) >= 0.45
         or exists (select 1 from unnest(t.syn) s where r.title ilike '%' || s || '%' or r.description ilike '%' || s || '%'))
  order by (r.offer_count >= 10), r.created_at desc
  limit least(greatest(p_limit, 1), 60) offset greatest(p_offset, 0);
$$;

-- One request page. Buyer identity only for the buyer themself, or for the
-- seller whose offer was accepted.
create or replace function public.get_request(p_request uuid)
returns table (
  id uuid, title text, description text, category_id smallint, budget_kobo bigint, state text, city text,
  deadline date, status public.request_status, created_at timestamptz, expires_at timestamptz,
  offer_count int, is_full boolean, is_owner boolean, buyer_username text,
  my_offer_id uuid, my_offer_status public.offer_status, my_offer_price_kobo bigint,
  my_offer_days int, my_offer_message text, my_offer_listing uuid, chat_id uuid)
language sql stable security definer set search_path = '' as $$
  select r.id, r.title, r.description, r.category_id, r.budget_kobo, r.state, r.city, r.deadline,
         case when r.status = 'open' and r.expires_at <= now() then 'expired'::public.request_status else r.status end,
         r.created_at, r.expires_at, r.offer_count, r.offer_count >= 10,
         coalesce(r.buyer_id = auth.uid(), false),
         case when r.buyer_id = auth.uid() or mo.status = 'accepted' then b.username end,
         mo.id, mo.status, mo.price_kobo, mo.delivery_days, mo.message, mo.listing_id,
         (select c.id from public.conversations c where c.request_offer_id = coalesce(mo.id, r.accepted_offer_id)
            and auth.uid() in (c.buyer_id, c.seller_id))
  from public.buyer_requests r
  join public.profiles b on b.id = r.buyer_id
  left join public.request_offers mo on mo.request_id = r.id and mo.seller_id = auth.uid()
  where r.id = p_request
    and public.account_ok(r.buyer_id)
    and (r.status = 'open' or r.buyer_id = auth.uid() or mo.id is not null);
$$;

-- Offers on your request, with each seller's public shop details.
create or replace function public.get_request_offers(p_request uuid)
returns table (
  id uuid, status public.offer_status, price_kobo bigint, delivery_days int, message text,
  created_at timestamptz, updated_at timestamptz,
  seller_id uuid, seller_username text, seller_name text, seller_avatar text, seller_verified boolean,
  seller_rating numeric, seller_rating_count int, seller_state text,
  listing_id uuid, listing_title text, chat_id uuid)
language sql stable security definer set search_path = '' as $$
  select o.id, o.status, o.price_kobo, o.delivery_days, o.message, o.created_at, o.updated_at,
         p.id, p.username, coalesce(p.business_name, p.display_name), p.avatar_url, p.is_verified,
         p.rating_avg, p.rating_count, p.state,
         l.id, l.title,
         (select c.id from public.conversations c where c.request_offer_id = o.id)
  from public.request_offers o
  join public.buyer_requests r on r.id = o.request_id
  join public.profiles p on p.id = o.seller_id
  left join public.listings l on l.id = o.listing_id and l.status = 'approved'
  where o.request_id = p_request and r.buyer_id = auth.uid()
    and o.status in ('sent', 'accepted', 'declined')
  order by (o.status = 'accepted') desc, (o.status = 'declined'), o.price_kobo;
$$;

-- Your requests (buyer) and your offers (seller), for dashboards.
create or replace function public.my_requests()
returns table (id uuid, title text, status public.request_status, offer_count int, new_offers bigint,
               created_at timestamptz, expires_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.id, r.title,
         case when r.status = 'open' and r.expires_at <= now() then 'expired'::public.request_status else r.status end,
         r.offer_count,
         (select count(*) from public.request_offers o where o.request_id = r.id and o.status = 'sent'),
         r.created_at, r.expires_at
  from public.buyer_requests r
  where r.buyer_id = auth.uid()
  order by (r.status = 'open') desc, r.created_at desc
  limit 100;
$$;

create or replace function public.my_offers()
returns table (offer_id uuid, request_id uuid, title text, offer_status public.offer_status,
               request_status public.request_status, price_kobo bigint, created_at timestamptz, chat_id uuid)
language sql stable security definer set search_path = '' as $$
  select o.id, r.id, r.title, o.status,
         case when r.status = 'open' and r.expires_at <= now() then 'expired'::public.request_status else r.status end,
         o.price_kobo, o.created_at,
         (select c.id from public.conversations c where c.request_offer_id = o.id)
  from public.request_offers o
  join public.buyer_requests r on r.id = o.request_id
  where o.seller_id = auth.uid()
  order by o.updated_at desc
  limit 100;
$$;

revoke execute on function
  public.create_request(text, text, smallint, bigint, text, text, date),
  public.update_request(uuid, text, text, smallint, bigint, text, text, date),
  public.close_request(uuid), public.send_offer(uuid, bigint, int, text, uuid), public.withdraw_offer(uuid),
  public.decline_offer(uuid), public.accept_offer(uuid), public.get_request_offers(uuid),
  public.my_requests(), public.my_offers()
  from public, anon;
grant execute on function
  public.create_request(text, text, smallint, bigint, text, text, date),
  public.update_request(uuid, text, text, smallint, bigint, text, text, date),
  public.close_request(uuid), public.send_offer(uuid, bigint, int, text, uuid), public.withdraw_offer(uuid),
  public.decline_offer(uuid), public.accept_offer(uuid), public.get_request_offers(uuid),
  public.my_requests(), public.my_offers()
  to authenticated;
revoke execute on function public.get_request_board(text, smallint, text, boolean, int, int), public.get_request(uuid) from public;
grant execute on function public.get_request_board(text, smallint, text, boolean, int, int), public.get_request(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- Reports can point at a request (the buyer stays hidden from the reporter).
-- ---------------------------------------------------------------------
alter table public.reports add column if not exists request_id uuid references public.buyer_requests(id) on delete cascade;
drop index if exists public.reports_one_open_per_target;
create unique index reports_one_open_per_target on public.reports
  (reporter_id, listing_id, reported_user_id, video_id, request_id) nulls not distinct where status = 'open';

-- (Applied as follow-up migrations "request_reports_keep_buyer_hidden" and
--  "request_reports_escalation" — final versions below.)
-- Request reports store only the request: reporters can read their own
-- reports, so the buyer must never be written into them.
alter table public.reports drop constraint if exists reports_check;
alter table public.reports drop constraint if exists reports_has_target;
alter table public.reports add constraint reports_has_target
  check (listing_id is not null or reported_user_id is not null or video_id is not null or request_id is not null);

create or replace function public.protect_report()
returns trigger
language plpgsql
set search_path = ''
as $$
declare request_buyer uuid;
begin
  if new.listing_id is not null then
    new.reported_user_id := public.listing_seller(new.listing_id);
    if new.reported_user_id is null then
      raise exception 'That listing no longer exists' using errcode = 'P0002';
    end if;
  elsif new.video_id is not null then
    new.reported_user_id := public.story_owner(new.video_id);
    if new.reported_user_id is null then
      raise exception 'That story no longer exists' using errcode = 'P0002';
    end if;
  elsif new.request_id is not null then
    request_buyer := private.request_owner(new.request_id);
    if request_buyer is null then
      raise exception 'That request no longer exists' using errcode = 'P0002';
    end if;
    new.reported_user_id := null;
  end if;

  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.reporter_id is distinct from auth.uid() then
      raise exception 'You can only send reports as yourself' using errcode = '42501';
    end if;
    if coalesce(new.reported_user_id, request_buyer) = auth.uid() then
      raise exception 'You can''t report yourself' using errcode = '42501';
    end if;
    if public.reports_sent_today() >= 10 then
      raise exception 'You''ve sent 10 reports today. Please try again tomorrow.' using errcode = '54000';
    end if;
    new.status          := 'open';
    new.handled_by      := null;
    new.handled_at      := null;
    new.resolution_note := null;
    new.details         := left(new.details, 2000);
  end if;
  return new;
end $$;

-- escalate_report(): adds a request branch — 3 reports from accounts older
-- than 3 days close the request, decline waiting offers, log it and raise a
-- high flag on the buyer. Full function as applied live; see
-- pg_get_functiondef('public.escalate_report()'::regprocedure).
