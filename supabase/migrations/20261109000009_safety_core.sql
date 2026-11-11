-- =====================================================================
-- Purple Vendra — safety layer 1: audit log, suspend/ban, private
-- delivery details (9 Nov 2026)
--
-- * security_events: an append-only record of sensitive actions.
--   Only admins (with 2FA) can read it. Nobody can edit or delete it.
-- * Account status (active / suspended / banned) on every profile.
--   A suspended or banned account can't create or change anything,
--   and its shop, listings and photos disappear from public view.
-- * Buyer delivery details (phone, address) and home-service addresses
--   are never readable directly. They are released one order at a
--   time, only to the right seller/pro, only while the job is active,
--   and every release is logged.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Audit log
-- ---------------------------------------------------------------------
create table public.security_events (
  id           bigint generated always as identity primary key,
  at           timestamptz not null default now(),
  actor_id     uuid,            -- who did it (null = system / SQL editor)
  action       text not null,   -- e.g. 'account_suspended'
  target_user  uuid,            -- whose data or account it concerns
  target_type  text,            -- e.g. 'order', 'booking', 'profile'
  target_id    text,
  details      jsonb not null default '{}'
);
create index security_events_at_idx on public.security_events (at desc);
create index security_events_target_user_idx on public.security_events (target_user, at desc);
create index security_events_actor_idx on public.security_events (actor_id, at desc);

alter table public.security_events enable row level security;

-- Append-only: no edits, no deletes. (Layer 3's retention job will
-- switch this on briefly with pv.allow_audit_purge to remove old rows.)
create or replace function public.block_security_event_changes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if coalesce(current_setting('pv.allow_audit_purge', true), '') <> 'on' then
    raise exception 'The security log cannot be changed or deleted' using errcode = '42501';
  end if;
  return old;
end $$;

create trigger security_events_append_only
  before update or delete on public.security_events
  for each row execute function public.block_security_event_changes();

-- Internal helper used by triggers and trusted functions only.
create or replace function public.log_security_event(
  p_action text, p_target_user uuid default null, p_target_type text default null,
  p_target_id text default null, p_details jsonb default '{}'
) returns void
language sql security definer set search_path = '' as $$
  insert into public.security_events (actor_id, action, target_user, target_type, target_id, details)
  values (auth.uid(), p_action, p_target_user, p_target_type, p_target_id, coalesce(p_details, '{}'));
$$;
revoke execute on function public.log_security_event(text, uuid, text, text, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Account status
-- ---------------------------------------------------------------------
create type public.account_status as enum ('active', 'suspended', 'banned');

alter table public.profiles
  add column account_status  public.account_status not null default 'active',
  add column status_reason   text,
  add column suspended_until timestamptz;

-- True when the user may act on the platform. A suspension with an end
-- date lifts itself when the date passes.
create or replace function public.account_ok(uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select p.account_status = 'active'
        or (p.account_status = 'suspended' and p.suspended_until is not null and p.suspended_until <= now())
    from public.profiles p where p.id = uid
  ), false);
$$;

-- Admins and posting both need a healthy account now.
create or replace function public.is_admin() returns boolean
language sql stable set search_path = '' as $$
  select public.current_role_is(array['admin']::public.user_role[])
     and public.has_aal2()
     and public.account_ok(auth.uid());
$$;

create or replace function public.can_post() returns boolean
language sql stable set search_path = '' as $$
  select public.current_role_is(array['seller', 'admin']::public.user_role[])
     and public.has_aal2()
     and public.account_ok(auth.uid());
$$;

-- Users can't change their own status (added to the protected fields).
create or replace function public.protect_profile_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.id              is distinct from old.id
    or new.role            is distinct from old.role
    or new.is_verified     is distinct from old.is_verified
    or new.referral_code   is distinct from old.referral_code
    or new.rating_avg      is distinct from old.rating_avg
    or new.rating_count    is distinct from old.rating_count
    or new.created_at      is distinct from old.created_at
    or new.account_status  is distinct from old.account_status
    or new.status_reason   is distinct from old.status_reason
    or new.suspended_until is distinct from old.suspended_until then
      raise exception 'You can''t change that part of your profile' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- Log changes to role, verification and status, whoever makes them.
create or replace function public.log_profile_changes() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.role is distinct from old.role then
    perform public.log_security_event('role_changed', new.id, 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.is_verified is distinct from old.is_verified then
    perform public.log_security_event('verified_badge_changed', new.id, 'profile', new.id::text,
      jsonb_build_object('to', new.is_verified));
  end if;
  if new.account_status is distinct from old.account_status
     or new.suspended_until is distinct from old.suspended_until then
    perform public.log_security_event('account_status_changed', new.id, 'profile', new.id::text,
      jsonb_build_object('from', old.account_status, 'to', new.account_status,
                         'reason', new.status_reason, 'until', new.suspended_until));
  end if;
  return null;
end $$;
revoke execute on function public.log_profile_changes() from public, anon, authenticated;

create trigger profiles_log_changes
  after update on public.profiles
  for each row execute function public.log_profile_changes();

-- Admin action: suspend, ban or restore an account (logged by the trigger).
create or replace function public.admin_set_account_status(
  target uuid, new_status public.account_status, reason text, until timestamptz default null
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can do this' using errcode = '42501';
  end if;
  if target = auth.uid() then
    raise exception 'You can''t change your own account status' using errcode = '42501';
  end if;
  if new_status <> 'active' and coalesce(trim(reason), '') = '' then
    raise exception 'Give a reason. The user will see it.' using errcode = '22023';
  end if;
  update public.profiles
  set account_status  = new_status,
      status_reason   = case when new_status = 'active' then null else reason end,
      suspended_until = case when new_status = 'suspended' then until else null end
  where id = target;
  if not found then
    raise exception 'No such user' using errcode = 'P0002';
  end if;
end $$;
revoke execute on function public.admin_set_account_status(uuid, public.account_status, text, timestamptz) from public, anon;
grant  execute on function public.admin_set_account_status(uuid, public.account_status, text, timestamptz) to authenticated;

-- Blocked accounts can't write anything, anywhere. These are
-- "restrictive" rules: they must pass on top of every other rule.
do $$
declare
  t   text;
  cmd text;
begin
  for t in select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
           where n.nspname = 'public' and c.relkind = 'r' and c.relname <> 'security_events' loop
    foreach cmd in array array['insert', 'update', 'delete'] loop
      if cmd = 'insert' then
        execute format('create policy %I on public.%I as restrictive for insert to authenticated with check ((select public.account_ok(auth.uid())))',
                       'Blocked accounts cannot ' || cmd, t);
      else
        execute format('create policy %I on public.%I as restrictive for %s to authenticated using ((select public.account_ok(auth.uid())))',
                       'Blocked accounts cannot ' || cmd, t, cmd);
      end if;
    end loop;
  end loop;
end $$;

create policy "Blocked accounts cannot upload"
  on storage.objects as restrictive for insert to authenticated
  with check ((select public.account_ok(auth.uid())));
create policy "Blocked accounts cannot change files"
  on storage.objects as restrictive for update to authenticated
  using ((select public.account_ok(auth.uid())));
create policy "Blocked accounts cannot delete files"
  on storage.objects as restrictive for delete to authenticated
  using ((select public.account_ok(auth.uid())));

-- Blocked sellers disappear from public view.
drop policy "Seller profiles are public" on public.profiles;
create policy "Seller profiles are public"
  on public.profiles for select to anon, authenticated
  using (role = 'seller' and public.account_ok(id));

drop policy "Approved listings are public" on public.listings;
create policy "Approved listings are public"
  on public.listings for select to anon, authenticated
  using (status = 'approved' and public.account_ok(seller_id));

drop policy "Photos of approved listings are public" on public.listing_images;
create policy "Photos of approved listings are public"
  on public.listing_images for select to anon, authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.status = 'approved' and public.account_ok(l.seller_id)
  ));

-- ---------------------------------------------------------------------
-- Log other sensitive changes
-- ---------------------------------------------------------------------
create or replace function public.log_verification_changes() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.id_document_path is distinct from old.id_document_path then
    perform public.log_security_event('id_submitted', new.user_id, 'seller_verification', new.user_id::text,
      jsonb_build_object('id_type', new.id_type));
  end if;
  if tg_op = 'UPDATE' and new.status is distinct from old.status and new.status in ('approved', 'rejected') then
    perform public.log_security_event('id_' || new.status::text, new.user_id, 'seller_verification', new.user_id::text,
      jsonb_build_object('reason', new.rejection_reason));
  end if;
  return null;
end $$;
revoke execute on function public.log_verification_changes() from public, anon, authenticated;

create trigger seller_verifications_log
  after insert or update on public.seller_verifications
  for each row execute function public.log_verification_changes();

create or replace function public.log_listing_moderation() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status is distinct from old.status and new.status in ('approved', 'rejected', 'removed')
     and auth.uid() is distinct from new.seller_id then
    perform public.log_security_event('listing_' || new.status::text, new.seller_id, 'listing', new.id::text,
      jsonb_build_object('reason', new.rejection_reason));
  end if;
  return null;
end $$;
revoke execute on function public.log_listing_moderation() from public, anon, authenticated;

create trigger listings_log_moderation
  after update on public.listings
  for each row execute function public.log_listing_moderation();

-- Admins write down when they open someone's ID document.
create or replace function public.admin_log_id_view(seller uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can do this' using errcode = '42501';
  end if;
  perform public.log_security_event('id_document_viewed', seller, 'seller_verification', seller::text);
end $$;
revoke execute on function public.admin_log_id_view(uuid) from public, anon;
grant  execute on function public.admin_log_id_view(uuid) to authenticated;

-- Only admins read the log.
create policy "Admins read the security log"
  on public.security_events for select to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------
-- Private delivery details
-- ---------------------------------------------------------------------
-- Buyers can see their own checkouts (and the delivery details they typed).
create policy "Buyers see their own checkouts"
  on public.checkouts for select to authenticated
  using (buyer_id = (select auth.uid()));

-- Buyers can see their own bookings; pros see bookings for them, but the
-- address column is only released through get_booking_address() below.
create policy "Buyers see their own bookings"
  on public.bookings for select to authenticated
  using (buyer_id = (select auth.uid()));

-- Sellers get a buyer's delivery details for ONE order, only while it
-- still needs delivering, only with 2FA, and the release is logged.
create or replace function public.get_order_delivery(p_order uuid)
returns table (delivery_name text, delivery_phone text, delivery_address text,
               delivery_city text, delivery_state text)
language plpgsql security definer set search_path = '' as $$
declare
  o record;
begin
  select ord.id, ord.seller_id, ord.buyer_id, ord.status, ord.checkout_id
  into o from public.orders ord where ord.id = p_order;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  if not public.is_admin() then
    if o.seller_id is distinct from auth.uid() then
      raise exception 'This is not your order' using errcode = '42501';
    end if;
    if not public.can_post() then
      raise exception 'Sign in with your 2FA code to see delivery details' using errcode = '42501';
    end if;
    if o.status not in ('paid', 'shipped', 'disputed') then
      raise exception 'Delivery details are only available while an order is being delivered' using errcode = '42501';
    end if;
  end if;

  perform public.log_security_event('delivery_details_viewed', o.buyer_id, 'order', o.id::text);

  return query
    select c.delivery_name, c.delivery_phone, c.delivery_address, c.delivery_city, c.delivery_state
    from public.checkouts c where c.id = o.checkout_id;
end $$;
revoke execute on function public.get_order_delivery(uuid) from public, anon;
grant  execute on function public.get_order_delivery(uuid) to authenticated;

-- Home-service pros get the job address only after they accept, while
-- the job is open, and the release is logged.
create or replace function public.get_booking_address(p_booking uuid)
returns table (service_address text, city text, state text)
language plpgsql security definer set search_path = '' as $$
declare
  b record;
begin
  select bk.id, bk.pro_id, bk.buyer_id, bk.status, bk.service_address, bk.city, bk.state
  into b from public.bookings bk where bk.id = p_booking;
  if not found then
    raise exception 'Booking not found' using errcode = 'P0002';
  end if;

  if not public.is_admin() then
    if b.pro_id is distinct from auth.uid() then
      raise exception 'This is not your booking' using errcode = '42501';
    end if;
    if not public.can_post() then
      raise exception 'Sign in with your 2FA code to see the address' using errcode = '42501';
    end if;
    if b.status not in ('accepted', 'scheduled', 'in_progress') then
      raise exception 'The address is shared once you accept the job, until it is finished' using errcode = '42501';
    end if;
  end if;

  perform public.log_security_event('booking_address_viewed', b.buyer_id, 'booking', b.id::text);
  return query select b.service_address, b.city, b.state;
end $$;
revoke execute on function public.get_booking_address(uuid) from public, anon;
grant  execute on function public.get_booking_address(uuid) to authenticated;
