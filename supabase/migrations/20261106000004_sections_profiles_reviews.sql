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
