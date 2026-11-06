-- =====================================================================
-- Purple Vendra — initial database schema
-- Step 2 of the backend plan (approved 6 Nov 2026)
--
-- Conventions
--   * All money is stored in KOBO as bigint (₦1 = 100 kobo).
--   * Every table has Row Level Security ENABLED with no policies yet,
--     which means "deny all" through the Supabase API until step 3
--     (auth & roles) adds the access rules.
--   * Anonymity rules are enforced by structure: save/cart notifications,
--     search logs and analytics events never store who did the action.
-- =====================================================================

create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------
create type user_role           as enum ('buyer', 'seller', 'admin');
create type verification_status as enum ('pending', 'approved', 'rejected');
create type listing_type        as enum ('product', 'service', 'talent');
create type listing_status      as enum ('draft', 'pending', 'approved', 'rejected', 'removed');
create type delivery_mode       as enum ('pickup', 'delivery', 'digital', 'in_person_service', 'remote_service');
create type checkout_status     as enum ('pending', 'paid', 'failed', 'abandoned');
create type order_status        as enum ('paid', 'shipped', 'delivered', 'completed', 'disputed', 'refunded', 'cancelled');
create type payout_status       as enum ('pending', 'processing', 'paid', 'failed');
create type dispute_status      as enum ('open', 'resolved_refund', 'resolved_release', 'closed');
create type report_status       as enum ('open', 'actioned', 'dismissed');
create type notification_type   as enum ('item_saved', 'item_carted', 'order_update', 'listing_review', 'verification_update', 'request_offer', 'new_message', 'payout_update', 'system');
create type commission_status   as enum ('pending', 'payable', 'paid', 'cancelled');
create type reward_status       as enum ('pending', 'earned', 'paid', 'void');
create type request_status      as enum ('open', 'closed', 'expired');
create type offer_status        as enum ('sent', 'accepted', 'declined', 'withdrawn');
create type listing_event_type  as enum ('view', 'save', 'cart', 'order', 'share_click');
create type content_type        as enum ('feature_post', 'meet_the_maker');
create type featured_status     as enum ('pending_payment', 'active', 'expired', 'refunded');

-- ---------------------------------------------------------------------
-- Helper: keep updated_at current
-- ---------------------------------------------------------------------
create or replace function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------
create table profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  role           user_role   not null default 'buyer',
  display_name   text        not null check (char_length(display_name) between 1 and 80),
  username       text        not null check (username ~ '^[a-z0-9_]{3,30}$'),
  avatar_url     text,
  bio            text        check (char_length(bio) <= 500),
  city           text,
  state          text,
  is_verified    boolean     not null default false,   -- set only when seller_verifications is approved
  referral_code  text        not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 8),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create unique index profiles_username_lower on profiles (lower(username));
create trigger profiles_updated_at before update on profiles
  for each row execute function set_updated_at();

-- Sensitive seller data lives apart from the public profile.
-- Full bank account numbers are NOT stored: only the payment provider's
-- recipient code and the last 4 digits for display.
create table seller_verifications (
  user_id                 uuid primary key references profiles(id) on delete cascade,
  status                  verification_status not null default 'pending',
  id_document_path        text,          -- path in the PRIVATE storage bucket
  bank_name               text,
  bank_code               text,
  account_name            text,
  account_last4           text check (account_last4 ~ '^[0-9]{4}$'),
  payment_recipient_code  text,          -- e.g. Paystack transfer recipient code
  rejection_reason        text,
  submitted_at            timestamptz not null default now(),
  reviewed_by             uuid references profiles(id),
  reviewed_at             timestamptz
);

create table follows (
  follower_id  uuid not null references profiles(id) on delete cascade,
  seller_id    uuid not null references profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, seller_id),
  check (follower_id <> seller_id)
);
create index follows_seller on follows (seller_id);

create table referrals (
  referrer_id    uuid not null references profiles(id) on delete cascade,
  referred_id    uuid primary key references profiles(id) on delete cascade,  -- a user can be referred once
  reward_status  reward_status not null default 'pending',
  created_at     timestamptz not null default now(),
  check (referrer_id <> referred_id)
);
create index referrals_referrer on referrals (referrer_id);

-- ---------------------------------------------------------------------
-- Catalogue
-- ---------------------------------------------------------------------
create table categories (
  id        smallserial primary key,
  slug      text not null unique,
  name      text not null,
  position  smallint not null default 0
);

insert into categories (slug, name, position) values
  ('fashion-ade',       'Fashion & Adé',          1),
  ('art-crafts',        'Art & Crafts',           2),
  ('digital-design',    'Digital & Design',       3),
  ('photo-video-talent','Photo, Video & Talent',  4),
  ('tech-freelance',    'Tech & Freelance',       5);

create table listings (
  id                 uuid primary key default gen_random_uuid(),
  seller_id          uuid not null references profiles(id) on delete cascade,
  type               listing_type   not null,
  category_id        smallint       not null references categories(id),
  title              text           not null check (char_length(title) between 3 and 120),
  description        text           not null check (char_length(description) <= 5000),
  price_kobo         bigint         not null check (price_kobo >= 0),
  price_is_starting  boolean        not null default false,  -- "from ₦X" for services/talent
  stock              integer        check (stock >= 0),      -- null = not stock-limited (services)
  delivery_mode      delivery_mode  not null,
  state              text,
  city               text,
  status             listing_status not null default 'pending',
  rejection_reason   text,
  featured_until     timestamptz,
  created_at         timestamptz    not null default now(),
  updated_at         timestamptz    not null default now(),
  search             tsvector generated always as (
                       setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
                       setweight(to_tsvector('english', coalesce(description, '')), 'B')
                     ) stored
);
create index listings_seller        on listings (seller_id);
create index listings_browse        on listings (category_id, status, created_at desc);
create index listings_featured      on listings (featured_until) where featured_until is not null;
create index listings_search        on listings using gin (search);
create index listings_title_trgm    on listings using gin (title gin_trgm_ops);
create trigger listings_updated_at before update on listings
  for each row execute function set_updated_at();

create table listing_images (
  id            uuid primary key default gen_random_uuid(),
  listing_id    uuid not null references listings(id) on delete cascade,
  storage_path  text not null,   -- path in the PUBLIC listing-images bucket
  position      smallint not null default 0,
  created_at    timestamptz not null default now(),
  unique (listing_id, position)
);

-- ---------------------------------------------------------------------
-- Save, cart, notifications
-- ---------------------------------------------------------------------
create table saves (
  user_id     uuid not null references profiles(id) on delete cascade,
  listing_id  uuid not null references listings(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index saves_listing on saves (listing_id);

create table cart_items (
  user_id     uuid not null references profiles(id) on delete cascade,
  listing_id  uuid not null references listings(id) on delete cascade,
  quantity    integer not null default 1 check (quantity between 1 and 99),
  added_at    timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index cart_items_listing on cart_items (listing_id);

-- Deliberately has NO actor/buyer column: an "item_saved" or
-- "item_carted" alert cannot reveal who did it.
create table notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references profiles(id) on delete cascade,
  type          notification_type not null,
  listing_id    uuid references listings(id) on delete set null,
  order_id      uuid,   -- FK added after orders table exists
  title         text not null,
  body          text,
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);
create index notifications_recipient on notifications (recipient_id, created_at desc);

-- ---------------------------------------------------------------------
-- Buyer request board
-- ---------------------------------------------------------------------
create table buyer_requests (
  id           uuid primary key default gen_random_uuid(),
  buyer_id     uuid not null references profiles(id) on delete cascade,
  category_id  smallint not null references categories(id),
  title        text not null check (char_length(title) between 3 and 120),
  description  text not null check (char_length(description) <= 2000),
  budget_kobo  bigint check (budget_kobo >= 0),
  deadline     date,
  state        text,
  city         text,
  status       request_status not null default 'open',
  created_at   timestamptz not null default now()
);
create index buyer_requests_open on buyer_requests (category_id, created_at desc) where status = 'open';

create table request_offers (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid not null references buyer_requests(id) on delete cascade,
  seller_id   uuid not null references profiles(id) on delete cascade,
  message     text not null check (char_length(message) between 1 and 1000),
  price_kobo  bigint not null check (price_kobo >= 0),
  status      offer_status not null default 'sent',
  created_at  timestamptz not null default now(),
  unique (request_id, seller_id)          -- one offer per seller per request
);
create index request_offers_seller_day on request_offers (seller_id, created_at);  -- for the daily offer limit

-- ---------------------------------------------------------------------
-- Conversations (buyer-started only)
-- ---------------------------------------------------------------------
create table conversations (
  id                uuid primary key default gen_random_uuid(),
  buyer_id          uuid not null references profiles(id) on delete cascade,
  seller_id         uuid not null references profiles(id) on delete cascade,
  listing_id        uuid references listings(id) on delete set null,
  request_offer_id  uuid references request_offers(id) on delete set null,
  created_at        timestamptz not null default now(),
  check (buyer_id <> seller_id)
);
create unique index conversations_unique_thread
  on conversations (buyer_id, seller_id, coalesce(listing_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index conversations_seller on conversations (seller_id);

create table messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references conversations(id) on delete cascade,
  sender_id        uuid not null references profiles(id) on delete cascade,
  body             text not null check (char_length(body) between 1 and 2000),
  read_at          timestamptz,
  created_at       timestamptz not null default now()
);
create index messages_conversation on messages (conversation_id, created_at);

-- ---------------------------------------------------------------------
-- Marketing: share links (sellers AND resellers)
-- ---------------------------------------------------------------------
create table share_links (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 10),
  listing_id  uuid not null references listings(id) on delete cascade,
  created_by  uuid not null references profiles(id) on delete cascade,
  clicks      integer not null default 0,
  created_at  timestamptz not null default now(),
  unique (listing_id, created_by)
);

-- ---------------------------------------------------------------------
-- Checkout, orders, money
-- ---------------------------------------------------------------------
create table checkouts (
  id                 uuid primary key default gen_random_uuid(),
  buyer_id           uuid not null references profiles(id),
  payment_reference  text unique,
  total_kobo         bigint not null check (total_kobo >= 0),
  status             checkout_status not null default 'pending',
  delivery_name      text,
  delivery_phone     text,
  delivery_address   text,
  delivery_city      text,
  delivery_state     text,
  paid_at            timestamptz,
  created_at         timestamptz not null default now()
);
create index checkouts_buyer on checkouts (buyer_id, created_at desc);

-- One order per seller per checkout. Purple Vendra's fee includes any
-- reseller commission (3% is paid OUT OF the platform fee), so the
-- seller's payout never changes because of a reseller.
create table orders (
  id                         uuid primary key default gen_random_uuid(),
  checkout_id                uuid not null references checkouts(id),
  buyer_id                   uuid not null references profiles(id),
  seller_id                  uuid not null references profiles(id),
  status                     order_status not null default 'paid',
  subtotal_kobo              bigint not null check (subtotal_kobo >= 0),
  delivery_fee_kobo          bigint not null default 0 check (delivery_fee_kobo >= 0),
  platform_fee_kobo          bigint not null check (platform_fee_kobo >= 0),
  reseller_commission_kobo   bigint not null default 0 check (reseller_commission_kobo >= 0),
  seller_payout_kobo         bigint not null check (seller_payout_kobo >= 0),
  share_link_id              uuid references share_links(id) on delete set null,
  shipped_at                 timestamptz,
  delivered_at               timestamptz,
  confirm_by                 timestamptz,   -- escrow window end; auto-release after this
  completed_at               timestamptz,
  created_at                 timestamptz not null default now(),
  check (buyer_id <> seller_id),
  check (reseller_commission_kobo <= platform_fee_kobo),
  check (seller_payout_kobo = subtotal_kobo + delivery_fee_kobo - platform_fee_kobo)
);
create index orders_checkout on orders (checkout_id);
create index orders_buyer    on orders (buyer_id, created_at desc);
create index orders_seller   on orders (seller_id, created_at desc);
create index orders_release  on orders (confirm_by) where status in ('shipped', 'delivered');

alter table notifications
  add constraint notifications_order_fk foreign key (order_id) references orders(id) on delete set null;

create table order_items (
  id               uuid primary key default gen_random_uuid(),
  order_id         uuid not null references orders(id) on delete cascade,
  listing_id       uuid references listings(id) on delete set null,
  title_snapshot   text not null,
  unit_price_kobo  bigint not null check (unit_price_kobo >= 0),
  quantity         integer not null check (quantity >= 1)
);
create index order_items_order on order_items (order_id);

create table payouts (
  id                  uuid primary key default gen_random_uuid(),
  order_id            uuid not null unique references orders(id),
  seller_id           uuid not null references profiles(id),
  amount_kobo         bigint not null check (amount_kobo >= 0),
  status              payout_status not null default 'pending',
  transfer_reference  text unique,
  paid_at             timestamptz,
  created_at          timestamptz not null default now()
);

create table reseller_commissions (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null unique references orders(id),
  reseller_id    uuid not null references profiles(id),
  share_link_id  uuid references share_links(id) on delete set null,
  amount_kobo    bigint not null check (amount_kobo >= 0),
  status         commission_status not null default 'pending',
  paid_at        timestamptz,
  created_at     timestamptz not null default now()
);
create index reseller_commissions_reseller on reseller_commissions (reseller_id, status);

create table disputes (
  id               uuid primary key default gen_random_uuid(),
  order_id         uuid not null unique references orders(id),
  opened_by        uuid not null references profiles(id),
  reason           text not null,
  details          text check (char_length(details) <= 3000),
  status           dispute_status not null default 'open',
  resolution_note  text,
  resolved_by      uuid references profiles(id),
  created_at       timestamptz not null default now(),
  resolved_at      timestamptz
);

create table featured_purchases (
  id                 uuid primary key default gen_random_uuid(),
  listing_id         uuid not null references listings(id) on delete cascade,
  seller_id          uuid not null references profiles(id),
  amount_kobo        bigint not null check (amount_kobo >= 0),
  starts_at          timestamptz not null,
  ends_at            timestamptz not null,
  payment_reference  text unique,
  status             featured_status not null default 'pending_payment',
  created_at         timestamptz not null default now(),
  check (ends_at > starts_at)
);

-- ---------------------------------------------------------------------
-- Trust & safety
-- ---------------------------------------------------------------------
create table reports (
  id                uuid primary key default gen_random_uuid(),
  reporter_id       uuid not null references profiles(id) on delete cascade,
  listing_id        uuid references listings(id) on delete cascade,
  reported_user_id  uuid references profiles(id) on delete cascade,
  reason            text not null,
  details           text check (char_length(details) <= 2000),
  status            report_status not null default 'open',
  handled_by        uuid references profiles(id),
  created_at        timestamptz not null default now(),
  check (listing_id is not null or reported_user_id is not null)
);
create index reports_open on reports (created_at) where status = 'open';

-- ---------------------------------------------------------------------
-- Insights & analytics (no user ids stored)
-- ---------------------------------------------------------------------
create table search_queries (
  id             bigserial primary key,
  query          text not null check (char_length(query) <= 200),
  category_id    smallint references categories(id),
  results_count  integer not null check (results_count >= 0),
  created_at     timestamptz not null default now()
);
create index search_queries_week on search_queries (created_at);

create table listing_events (
  id          bigserial primary key,
  listing_id  uuid not null references listings(id) on delete cascade,
  event_type  listing_event_type not null,
  created_at  timestamptz not null default now()
);
create index listing_events_listing on listing_events (listing_id, event_type, created_at);

create table content_features (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid not null references profiles(id) on delete cascade,
  listing_id    uuid references listings(id) on delete set null,
  content_type  content_type not null,
  channel       text not null,      -- instagram, tiktok, youtube, whatsapp...
  publish_date  date,
  url           text,
  created_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Lock everything down until step 3 adds access policies
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','seller_verifications','follows','referrals','categories',
    'listings','listing_images','saves','cart_items','notifications',
    'buyer_requests','request_offers','conversations','messages',
    'share_links','checkouts','orders','order_items','payouts',
    'reseller_commissions','disputes','featured_purchases','reports',
    'search_queries','listing_events','content_features'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;
