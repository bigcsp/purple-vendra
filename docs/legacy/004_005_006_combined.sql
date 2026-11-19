-- Purple Vendra: migrations 004, 005 and 006 in one paste (9 Nov 2026).
-- Supabase → SQL Editor → New query → paste ALL of this → Run.
-- It runs as one transaction: if anything fails, nothing is changed.

begin;

-- ===================== 20261106000004_sections_profiles_reviews.sql =====================
-- =====================================================================
-- Purple Vendra — three marketplaces, professional profiles, reviews
-- (approved 6 Nov 2026)
--
-- Mission: help people turn their skills into visible,
-- discoverable businesses.
--
-- * Sections: Creative, Freelance and Home Services marketplaces sit
--   above the 6 categories. All share one discovery, profiles,
--   reviews and promotion tools.
-- * Professional profiles: business name, headline, years of
--   experience, availability, working hours, rating.
-- * Reviews: only from a COMPLETED order or booking, one per job,
--   one public reply from the pro, admins can hide (never edit).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Sections (the three connected marketplaces)
-- ---------------------------------------------------------------------
create table sections (
  id        smallserial primary key,
  slug      text not null unique,
  name      text not null,
  tagline   text not null,
  position  smallint not null default 0
);

insert into sections (slug, name, tagline, position) values
  ('creative',      'Creative Marketplace',      'Artists, designers, photographers, models and creative talent', 1),
  ('freelance',     'Freelance Marketplace',     'Independent professionals offering digital and professional services', 2),
  ('home-services', 'Home Services Marketplace', 'Plumbers, electricians, cleaners, painters and repair technicians', 3);

alter table categories add column section_id smallint references sections(id);

update categories set section_id = (select id from sections where slug = 'creative')
  where slug in ('fashion-ade', 'art-crafts', 'digital-design', 'photo-video-talent');
update categories set section_id = (select id from sections where slug = 'freelance')
  where slug = 'tech-freelance';
update categories set section_id = (select id from sections where slug = 'home-services')
  where slug = 'home-services';

alter table categories alter column section_id set not null;
create index categories_section on categories (section_id, position);

alter table sections enable row level security;
create policy "Sections are public"
  on public.sections for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------
-- Professional profile fields
-- ---------------------------------------------------------------------
alter table profiles
  add column business_name     text check (char_length(business_name) <= 80),
  add column headline          text check (char_length(headline) <= 80),   -- e.g. "Home Repair Specialist"
  add column years_experience  smallint check (years_experience between 0 and 80),
  add column is_available      boolean not null default true,              -- "Available now" / "On break"
  add column rating_avg        numeric(2,1),                               -- kept up to date by trigger
  add column rating_count      integer not null default 0;

-- "Quote on request" services (price shown as "Get a quote")
alter table listings
  add column quote_on_request boolean not null default false;

-- Opening hours per day (0 = Sunday ... 6 = Saturday)
create table working_hours (
  seller_id    uuid not null references profiles(id) on delete cascade,
  day_of_week  smallint not null check (day_of_week between 0 and 6),
  opens_at     time not null,
  closes_at    time not null,
  primary key (seller_id, day_of_week),
  check (closes_at > opens_at)
);
alter table working_hours enable row level security;

-- ---------------------------------------------------------------------
-- Verified reviews
-- ---------------------------------------------------------------------
create table reviews (
  id                 uuid primary key default gen_random_uuid(),
  order_id           uuid unique references orders(id),
  booking_id         uuid unique references bookings(id),
  reviewer_id        uuid not null references profiles(id) on delete cascade,
  seller_id          uuid not null references profiles(id) on delete cascade,
  rating             smallint not null check (rating between 1 and 5),
  body               text check (char_length(body) <= 1000),
  seller_reply       text check (char_length(seller_reply) <= 1000),
  seller_replied_at  timestamptz,
  is_hidden          boolean not null default false,
  hidden_by          uuid references profiles(id),
  created_at         timestamptz not null default now(),
  check (order_id is not null or booking_id is not null)
);
create index reviews_seller on reviews (seller_id, created_at desc) where not is_hidden;
alter table reviews enable row level security;

-- Only the buyer of a COMPLETED job can review, and only that job's seller.
create or replace function validate_review() returns trigger
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if new.order_id is not null then
    select exists (
      select 1 from orders o
      where o.id = new.order_id
        and o.buyer_id = new.reviewer_id
        and o.seller_id = new.seller_id
        and o.status = 'completed'
    ) into ok;
  else
    select exists (
      select 1 from bookings b
      where b.id = new.booking_id
        and b.buyer_id = new.reviewer_id
        and b.pro_id = new.seller_id
        and b.status = 'completed'
    ) into ok;
  end if;

  if not ok then
    raise exception 'Reviews can only be left by the customer of a completed order or booking'
      using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger reviews_validate
  before insert on reviews
  for each row execute function validate_review();

-- Customers can't rewrite history: rating, text and links are fixed once posted.
create or replace function protect_review() returns trigger
language plpgsql as $$
begin
  if new.rating is distinct from old.rating
     or new.body is distinct from old.body
     or new.reviewer_id is distinct from old.reviewer_id
     or new.seller_id is distinct from old.seller_id
     or new.order_id is distinct from old.order_id
     or new.booking_id is distinct from old.booking_id then
    raise exception 'A posted review cannot be edited' using errcode = 'P0001';
  end if;
  if old.seller_reply is not null and new.seller_reply is distinct from old.seller_reply then
    raise exception 'The pro can reply to a review only once' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger reviews_protect
  before update on reviews
  for each row execute function protect_review();

-- Keep each profile's average rating and review count up to date
create or replace function refresh_seller_rating() returns trigger
language plpgsql security definer set search_path = public as $$
declare sid uuid := coalesce(new.seller_id, old.seller_id);
begin
  update profiles p set
    rating_avg   = s.avg_rating,
    rating_count = s.n
  from (
    select round(avg(rating)::numeric, 1) as avg_rating, count(*)::int as n
    from reviews where seller_id = sid and not is_hidden
  ) s
  where p.id = sid;
  return null;
end $$;

create trigger reviews_rating_refresh
  after insert or update or delete on reviews
  for each row execute function refresh_seller_rating();

-- ===================== 20261106000005_rename_fashion_adire.sql =====================
-- Purple Vendra — rename "Fashion & Adé" to "Fashion & Adire" (6 Nov 2026)

update categories
set name = 'Fashion & Adire',
    slug = 'fashion-adire'
where slug = 'fashion-ade';

-- ===================== 20261109000006_auth_roles_seller_2fa.sql =====================
-- =====================================================================
-- Purple Vendra — backend step 3: sign-in, roles and the seller 2FA rule
-- (9 Nov 2026)
--
-- * Every new sign-up gets a profile automatically (role = buyer).
-- * Nobody can make themselves a seller, admin or "verified" by editing
--   their own profile. Those fields are protected.
-- * Becoming a seller requires a verified authenticator app (2FA) AND a
--   session that was confirmed with a 6-digit code (Supabase "aal2").
-- * THE 2FA RULE: posting or changing listings, photos, quotes,
--   service areas and working hours is blocked by the database unless
--   the user is a seller signed in with 2FA. The website can't skip it.
-- * Admin powers only work from a 2FA-confirmed session too.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Helper checks used by the access rules
-- ---------------------------------------------------------------------

-- True when the current session was confirmed with an authenticator code.
create or replace function public.has_aal2() returns boolean
language sql stable set search_path = '' as $$
  select coalesce(auth.jwt() ->> 'aal', '') = 'aal2';
$$;

create or replace function public.current_role_is(wanted public.user_role[]) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = any (wanted)
  );
$$;

-- Admin = admin role AND a 2FA-confirmed session.
create or replace function public.is_admin() returns boolean
language sql stable set search_path = '' as $$
  select public.current_role_is(array['admin']::public.user_role[]) and public.has_aal2();
$$;

-- Seller (or admin) signed in with 2FA: the only people who can post.
create or replace function public.can_post() returns boolean
language sql stable set search_path = '' as $$
  select public.current_role_is(array['seller', 'admin']::public.user_role[]) and public.has_aal2();
$$;

-- ---------------------------------------------------------------------
-- Create a profile for every new sign-up
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  wanted_username text := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  wanted_name     text := trim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
  final_username  text;
begin
  if wanted_username ~ '^[a-z0-9_]{3,30}$'
     and not exists (select 1 from public.profiles where lower(username) = wanted_username) then
    final_username := wanted_username;
  else
    final_username := 'user_' || substr(replace(new.id::text, '-', ''), 1, 10);
  end if;

  if wanted_name = '' then
    wanted_name := coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'New member');
  end if;

  insert into public.profiles (id, role, display_name, username)
  values (new.id, 'buyer', left(wanted_name, 80), final_username);

  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Give any accounts created before this migration a profile too.
insert into public.profiles (id, role, display_name, username)
select u.id,
       'buyer',
       left(coalesce(nullif(split_part(coalesce(u.email, ''), '@', 1), ''), 'New member'), 80),
       'user_' || substr(replace(u.id::text, '-', ''), 1, 10)
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- Lets the sign-up form say "that username is taken" before submitting.
create or replace function public.username_available(wanted text) returns boolean
language sql stable security definer set search_path = '' as $$
  select lower(wanted) ~ '^[a-z0-9_]{3,30}$'
     and not exists (select 1 from public.profiles where lower(username) = lower(wanted));
$$;

-- ---------------------------------------------------------------------
-- Protect fields users must not change on their own profile
-- ---------------------------------------------------------------------
create or replace function public.protect_profile_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  -- Only requests coming from the website (anon / authenticated) are
  -- checked. The SQL editor and trusted database functions are not.
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.id            is distinct from old.id
    or new.role          is distinct from old.role
    or new.is_verified   is distinct from old.is_verified
    or new.referral_code is distinct from old.referral_code
    or new.rating_avg    is distinct from old.rating_avg
    or new.rating_count  is distinct from old.rating_count
    or new.created_at    is distinct from old.created_at then
      raise exception 'You can''t change that part of your profile' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists profiles_protect_fields on public.profiles;
create trigger profiles_protect_fields
  before update on public.profiles
  for each row execute function public.protect_profile_fields();

-- ---------------------------------------------------------------------
-- Become a seller (needs 2FA)
-- ---------------------------------------------------------------------
create or replace function public.become_seller() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;

  if not exists (
    select 1 from auth.mfa_factors f
    where f.user_id = auth.uid() and f.status = 'verified'
  ) then
    raise exception 'Turn on two-factor authentication before you start selling' using errcode = '42501';
  end if;

  if not public.has_aal2() then
    raise exception 'Confirm with your authenticator code first' using errcode = '42501';
  end if;

  update public.profiles set role = 'seller' where id = auth.uid() and role = 'buyer';
end $$;

revoke execute on function public.become_seller() from public, anon;
grant  execute on function public.become_seller() to authenticated;

-- ---------------------------------------------------------------------
-- Listings: sellers can't approve or feature their own listings
-- ---------------------------------------------------------------------
create or replace function public.protect_listing_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.status not in ('draft', 'pending') then
        raise exception 'Listings are approved by the Purple Vendra team' using errcode = '42501';
      end if;
      if new.featured_until is not null or new.rejection_reason is not null then
        raise exception 'You can''t set that field on a new listing' using errcode = '42501';
      end if;
    else
      if new.status is distinct from old.status
         and new.status not in ('draft', 'pending', 'removed') then
        raise exception 'Listings are approved by the Purple Vendra team' using errcode = '42501';
      end if;
      if new.seller_id        is distinct from old.seller_id
      or new.featured_until   is distinct from old.featured_until
      or new.rejection_reason is distinct from old.rejection_reason then
        raise exception 'You can''t change that part of a listing' using errcode = '42501';
      end if;
      -- Changing what an approved listing says or costs sends it back for review.
      if old.status = 'approved' and new.status = 'approved'
         and (new.title         is distinct from old.title
           or new.description   is distinct from old.description
           or new.price_kobo    is distinct from old.price_kobo
           or new.category_id   is distinct from old.category_id
           or new.type          is distinct from old.type
           or new.delivery_mode is distinct from old.delivery_mode) then
        new.status := 'pending';
      end if;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists listings_protect_fields on public.listings;
create trigger listings_protect_fields
  before insert or update on public.listings
  for each row execute function public.protect_listing_fields();

-- =====================================================================
-- Access rules (Row Level Security policies)
-- =====================================================================

-- Profiles ------------------------------------------------------------
create policy "Seller profiles are public"
  on public.profiles for select to anon, authenticated
  using (role = 'seller');

create policy "Users can see their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "Admins can see all profiles"
  on public.profiles for select to authenticated
  using ((select public.is_admin()));

create policy "Users can edit their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Admins can edit any profile"
  on public.profiles for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- Seller verification (ID upload and admin review come in steps 4 and 8)
create policy "Sellers can see their own verification"
  on public.seller_verifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Admins can see all verifications"
  on public.seller_verifications for select to authenticated
  using ((select public.is_admin()));

-- Listings ------------------------------------------------------------
create policy "Approved listings are public"
  on public.listings for select to anon, authenticated
  using (status = 'approved');

create policy "Sellers can see their own listings"
  on public.listings for select to authenticated
  using (seller_id = (select auth.uid()));

create policy "Sellers can create their own listings"
  on public.listings for insert to authenticated
  with check (seller_id = (select auth.uid()));

create policy "Sellers can edit their own listings"
  on public.listings for update to authenticated
  using (seller_id = (select auth.uid()))
  with check (seller_id = (select auth.uid()));

create policy "Admins can see and moderate all listings"
  on public.listings for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- ---------------------------------------------------------------------
-- THE SELLER 2FA RULE
-- "Restrictive" policies must ALSO pass, on top of the rules above.
-- No seller role or no 2FA-confirmed session = no posting, no edits.
-- ---------------------------------------------------------------------
do $$
declare
  t   text;
  cmd text;
begin
  foreach t in array array['listings', 'listing_images', 'service_areas', 'working_hours'] loop
    foreach cmd in array array['insert', 'update', 'delete'] loop
      if cmd = 'insert' then
        execute format(
          'create policy %I on public.%I as restrictive for insert to anon, authenticated with check ((select public.can_post()))',
          'Sellers must use 2FA to ' || cmd, t);
      else
        execute format(
          'create policy %I on public.%I as restrictive for %s to anon, authenticated using ((select public.can_post()))',
          'Sellers must use 2FA to ' || cmd, t, cmd);
      end if;
    end loop;
  end loop;
end $$;

create policy "Sellers must use 2FA to send quotes"
  on public.request_offers as restrictive for insert to anon, authenticated
  with check ((select public.can_post()));

commit;
