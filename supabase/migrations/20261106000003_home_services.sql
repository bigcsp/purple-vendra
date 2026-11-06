-- =====================================================================
-- Purple Vendra — Home Services & Repairs (added 6 Nov 2026)
--
-- * New 6th category: plumbing, electrical, AC & generator repair,
--   carpentry, painting, tiling, cleaning, fumigation...
-- * Pricing: fixed-price services (book directly) OR quote-based jobs
--   (buyer posts on the request board, pros send quotes).
-- * Payment is held in escrow until the customer confirms the job is done.
-- * Safety: a home-service listing can only go live once the pro's ID
--   verification is APPROVED (stricter than other categories).
-- =====================================================================

insert into categories (slug, name, position)
values ('home-services', 'Home Services & Repairs', 6);

-- Areas a pro is willing to travel to
create table service_areas (
  seller_id   uuid not null references profiles(id) on delete cascade,
  state       text not null,
  city        text not null,          -- city or LGA, e.g. "Ikeja", "Lekki"
  created_at  timestamptz not null default now(),
  primary key (seller_id, state, city)
);
create index service_areas_lookup on service_areas (state, city);

create type booking_status as enum (
  'requested',    -- customer asked for a date
  'accepted',     -- pro accepted; customer can now pay (escrow)
  'declined',
  'scheduled',    -- paid, visit booked
  'in_progress',
  'completed',    -- customer confirmed -> escrow release
  'cancelled'
);
create type time_window as enum ('morning', 'afternoon', 'evening');

-- A booking is created BEFORE payment (request -> accept -> pay -> visit).
-- order_id is filled in once the customer pays.
create table bookings (
  id                uuid primary key default gen_random_uuid(),
  buyer_id          uuid not null references profiles(id),
  pro_id            uuid not null references profiles(id),
  listing_id        uuid references listings(id) on delete set null,       -- fixed-price booking
  request_offer_id  uuid references request_offers(id) on delete set null, -- quote-based booking
  order_id          uuid unique references orders(id),
  job_details       text not null check (char_length(job_details) <= 2000),
  service_address   text not null,   -- shown to the pro only after they accept (enforced in step 3)
  city              text not null,
  state             text not null,
  preferred_date    date not null,
  preferred_window  time_window not null,
  scheduled_at      timestamptz,
  status            booking_status not null default 'requested',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (buyer_id <> pro_id),
  check (listing_id is not null or request_offer_id is not null)
);
create index bookings_pro   on bookings (pro_id, preferred_date);
create index bookings_buyer on bookings (buyer_id, created_at desc);
create trigger bookings_updated_at before update on bookings
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- Safety rule: home-service listings need an APPROVED ID verification
-- before they can be submitted or go live.
-- ---------------------------------------------------------------------
create or replace function enforce_home_service_verification() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status in ('pending', 'approved')
     and new.category_id = (select id from categories where slug = 'home-services')
     and not exists (
       select 1 from seller_verifications v
       where v.user_id = new.seller_id and v.status = 'approved'
     )
  then
    raise exception 'Home-service pros must have an approved ID verification before listing'
      using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger listings_home_service_check
  before insert or update of status, category_id on listings
  for each row execute function enforce_home_service_verification();

alter table service_areas enable row level security;
alter table bookings      enable row level security;
