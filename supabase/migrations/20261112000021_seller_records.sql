-- =====================================================================
-- 021 · Permanent seller records
--   seller_register        one row per seller, forever (seller number PS-000001…)
--   seller_milestones      onboarding timeline, append-only
--   seller_status_history  every status change with who/when/why, append-only
-- Everything is recorded automatically by database triggers, so the record
-- is complete no matter which screen (or SQL) made the change.
-- When an account is deleted, personal details in the register are
-- removed but the anonymised business record and its history stay.
-- =====================================================================

create type public.seller_milestone as enum (
  'signed_up', 'two_factor_on', 'shop_opened', 'profile_completed',
  'first_listing_approved', 'id_verified', 'bank_verified', 'first_sale', 'first_payout');

create type public.register_status as enum ('active', 'suspended', 'banned', 'deleted');

create table public.seller_register (
  seller_no     bigint generated always as identity primary key,
  seller_id     uuid unique references public.profiles(id) on delete set null,
  shop_name     text,
  username      text,
  state         text,
  city          text,
  signed_up_at  timestamptz,
  joined_at     timestamptz not null default now(),       -- became a seller
  joined_is_estimate boolean not null default false,       -- true for sellers from before this record existed
  status        public.register_status not null default 'active',
  status_reason text,
  id_status     public.verification_status,
  bank_verified boolean not null default false,
  anonymised_at timestamptz,
  updated_at    timestamptz not null default now()
);
comment on table public.seller_register is 'One permanent row per seller. Never deleted; anonymised when the account is deleted.';

create table public.seller_milestones (
  seller_no   bigint not null references public.seller_register(seller_no) on delete restrict,
  milestone   public.seller_milestone not null,
  reached_at  timestamptz not null,
  source      text not null default 'live' check (source in ('live', 'backfill')),
  recorded_at timestamptz not null default now(),
  primary key (seller_no, milestone)
);

create table public.seller_status_history (
  id          bigint generated always as identity primary key,
  seller_no   bigint not null references public.seller_register(seller_no) on delete restrict,
  from_status public.register_status,
  to_status   public.register_status not null,
  reason      text,
  changed_by  uuid,             -- the admin (or the seller themself); kept even if that account goes
  changed_at  timestamptz not null default now()
);
create index seller_status_history_seller on public.seller_status_history (seller_no, changed_at);

-- ---------------------------------------------------------------------
-- History can't be edited or deleted by anyone.
-- ---------------------------------------------------------------------
create or replace function public.forbid_history_change()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception '% is a permanent record and can''t be changed or deleted', tg_table_name using errcode = '42501';
end $$;

create trigger seller_milestones_append_only before update or delete on public.seller_milestones
  for each row execute function public.forbid_history_change();
create trigger seller_milestones_no_truncate before truncate on public.seller_milestones
  for each statement execute function public.forbid_history_change();
create trigger seller_status_history_append_only before update or delete on public.seller_status_history
  for each row execute function public.forbid_history_change();
create trigger seller_status_history_no_truncate before truncate on public.seller_status_history
  for each statement execute function public.forbid_history_change();
create trigger seller_register_no_delete before delete on public.seller_register
  for each row execute function public.forbid_history_change();
create trigger seller_register_no_truncate before truncate on public.seller_register
  for each statement execute function public.forbid_history_change();

-- ---------------------------------------------------------------------
-- Who can read: sellers see their own record, admins see everything.
-- Nobody writes through the API; triggers below do all the writing.
-- ---------------------------------------------------------------------
alter table public.seller_register enable row level security;
alter table public.seller_milestones enable row level security;
alter table public.seller_status_history enable row level security;

create policy "Sellers see their own register entry" on public.seller_register
  for select to authenticated using (seller_id = (select auth.uid()) or (select public.is_admin()));
create policy "Sellers see their own milestones" on public.seller_milestones
  for select to authenticated using (
    (select public.is_admin())
    or exists (select 1 from public.seller_register r where r.seller_no = seller_milestones.seller_no and r.seller_id = (select auth.uid())));
create policy "Sellers see their own status history" on public.seller_status_history
  for select to authenticated using (
    (select public.is_admin())
    or exists (select 1 from public.seller_register r where r.seller_no = seller_status_history.seller_no and r.seller_id = (select auth.uid())));

revoke all on public.seller_register, public.seller_milestones, public.seller_status_history from anon;
revoke insert, update, delete, truncate, references, trigger
  on public.seller_register, public.seller_milestones, public.seller_status_history from authenticated;
grant select on public.seller_register, public.seller_milestones, public.seller_status_history to authenticated;

-- ---------------------------------------------------------------------
-- Writers (internal; not callable from the website API)
-- ---------------------------------------------------------------------
create or replace function private.register_status_of(p public.profiles)
returns public.register_status language sql immutable set search_path = '' as $$
  select case when p.deleted_at is not null then 'deleted'::public.register_status
              else p.account_status::text::public.register_status end;
$$;

-- Make sure a seller has a register row; returns their seller number.
create or replace function private.ensure_seller_register(p_seller uuid)
returns bigint language plpgsql security definer set search_path = '' as $$
declare
  n bigint;
  p public.profiles;
begin
  select seller_no into n from public.seller_register where seller_id = p_seller;
  if n is not null then return n; end if;
  select * into p from public.profiles where id = p_seller;
  if p.id is null then return null; end if;
  insert into public.seller_register (seller_id, shop_name, username, state, city, signed_up_at, joined_at, status)
  values (p.id, coalesce(p.business_name, p.display_name), p.username, p.state, p.city, p.created_at, now(),
          private.register_status_of(p))
  returning seller_no into n;
  insert into public.seller_status_history (seller_no, from_status, to_status, reason, changed_by)
  values (n, null, private.register_status_of(p), 'Became a seller', p.id);
  return n;
end $$;

create or replace function private.add_milestone(
  p_seller uuid, p_milestone public.seller_milestone, p_at timestamptz default now(), p_source text default 'live')
returns void language plpgsql security definer set search_path = '' as $$
declare n bigint;
begin
  n := private.ensure_seller_register(p_seller);
  if n is null then return; end if;
  insert into public.seller_milestones (seller_no, milestone, reached_at, source)
  values (n, p_milestone, coalesce(p_at, now()), p_source)
  on conflict (seller_no, milestone) do nothing;
end $$;

revoke all on function private.register_status_of(public.profiles), private.ensure_seller_register(uuid),
  private.add_milestone(uuid, public.seller_milestone, timestamptz, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Triggers that keep the record up to date
-- ---------------------------------------------------------------------

-- Profiles: becoming a seller, profile details, status changes, deletion.
create or replace function private.track_seller_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  n bigint;
  old_status public.register_status;
  new_status public.register_status;
begin
  -- Became a seller.
  if new.role in ('seller', 'admin') and old.role = 'buyer' then
    perform private.add_milestone(new.id, 'signed_up', new.created_at);
    perform private.add_milestone(new.id, 'two_factor_on',
      coalesce((select min(f.created_at) from auth.mfa_factors f where f.user_id = new.id and f.status = 'verified'), now()));
    perform private.add_milestone(new.id, 'shop_opened', now());
  end if;

  select seller_no into n from public.seller_register where seller_id = new.id;
  if n is null then
    return null;
  end if;

  -- Deleted (anonymised mode): wipe personal details from the register.
  if new.deleted_at is not null and old.deleted_at is null then
    update public.seller_register
    set shop_name = 'Deleted seller #' || seller_no, username = null, city = null,
        status = 'deleted', status_reason = 'Account deleted at the seller''s request',
        anonymised_at = now(), bank_verified = false, updated_at = now()
    where seller_no = n;
    insert into public.seller_status_history (seller_no, from_status, to_status, reason, changed_by)
    values (n, private.register_status_of(old), 'deleted', 'Account deleted at the seller''s request', auth.uid());
    return null;
  end if;
  if new.deleted_at is not null then
    return null;
  end if;

  -- Keep the snapshot current.
  update public.seller_register
  set shop_name = coalesce(new.business_name, new.display_name), username = new.username,
      state = new.state, city = new.city, updated_at = now()
  where seller_no = n
    and (shop_name, username, state, city) is distinct from (coalesce(new.business_name, new.display_name), new.username, new.state, new.city);

  -- Profile completed: shop name, headline, about and location filled in.
  if new.business_name is not null and new.headline is not null and new.bio is not null and new.state is not null then
    perform private.add_milestone(new.id, 'profile_completed', now());
  end if;

  -- Status change (suspended, banned, back to active).
  old_status := private.register_status_of(old);
  new_status := private.register_status_of(new);
  if new_status is distinct from old_status then
    update public.seller_register set status = new_status, status_reason = new.status_reason, updated_at = now()
    where seller_no = n;
    insert into public.seller_status_history (seller_no, from_status, to_status, reason, changed_by)
    values (n, old_status, new_status, new.status_reason, auth.uid());
  end if;
  return null;
end $$;

create trigger profiles_track_seller after update on public.profiles
  for each row execute function private.track_seller_profile();

-- Profiles: full deletion (accounts with no money history are removed).
create or replace function private.track_seller_deleted()
returns trigger language plpgsql security definer set search_path = '' as $$
declare n bigint;
begin
  select seller_no into n from public.seller_register where seller_id = old.id;
  if n is not null then
    update public.seller_register
    set shop_name = 'Deleted seller #' || seller_no, username = null, city = null,
        status = 'deleted', status_reason = 'Account deleted at the seller''s request',
        anonymised_at = now(), bank_verified = false, updated_at = now()
    where seller_no = n and status <> 'deleted';
    if found then
      insert into public.seller_status_history (seller_no, from_status, to_status, reason, changed_by)
      values (n, private.register_status_of(old), 'deleted', 'Account deleted at the seller''s request', auth.uid());
    end if;
  end if;
  return old;
end $$;

create trigger profiles_track_seller_deleted before delete on public.profiles
  for each row execute function private.track_seller_deleted();

-- Listings: first listing approved.
create or replace function private.track_first_listing()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'approved' and (tg_op = 'INSERT' or old.status is distinct from 'approved') then
    perform private.add_milestone(new.seller_id, 'first_listing_approved', now());
  end if;
  return null;
end $$;
create trigger listings_track_first_approved after insert or update of status on public.listings
  for each row execute function private.track_first_listing();

-- ID and bank verification.
create or replace function private.track_verification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare n bigint;
begin
  n := private.ensure_seller_register(new.user_id);
  if n is null then return null; end if;
  update public.seller_register
  set id_status = new.status,
      bank_verified = (new.status = 'approved' and new.payment_recipient_code is not null),
      updated_at = now()
  where seller_no = n;
  if new.status = 'approved' then
    perform private.add_milestone(new.user_id, 'id_verified', coalesce(new.reviewed_at, now()));
    if new.payment_recipient_code is not null then
      perform private.add_milestone(new.user_id, 'bank_verified', now());
    end if;
  end if;
  return null;
end $$;
create trigger seller_verifications_track after insert or update on public.seller_verifications
  for each row execute function private.track_verification();

-- Orders: first sale (paid). Payouts: first payout (paid).
create or replace function private.track_first_sale()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status in ('paid', 'shipped', 'delivered', 'completed') then
    perform private.add_milestone(new.seller_id, 'first_sale', now());
  end if;
  return null;
end $$;
create trigger orders_track_first_sale after insert or update of status on public.orders
  for each row execute function private.track_first_sale();

create or replace function private.track_first_payout()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'paid' then
    perform private.add_milestone(new.seller_id, 'first_payout', coalesce(new.paid_at, now()));
  end if;
  return null;
end $$;
create trigger payouts_track_first_payout after insert or update of status on public.payouts
  for each row execute function private.track_first_payout();

revoke all on function private.track_seller_profile(), private.track_seller_deleted(), private.track_first_listing(),
  private.track_verification(), private.track_first_sale(), private.track_first_payout() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Readers
-- ---------------------------------------------------------------------

-- A seller's own progress (for the seller hub).
create or replace function public.my_seller_progress()
returns table (seller_no bigint, joined_at timestamptz, milestone public.seller_milestone, reached_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.seller_no, r.joined_at, m.milestone, sm.reached_at
  from public.seller_register r
  cross join unnest(enum_range(null::public.seller_milestone)) as m(milestone)
  left join public.seller_milestones sm on sm.seller_no = r.seller_no and sm.milestone = m.milestone
  where r.seller_id = auth.uid()
  order by m.milestone;
$$;
revoke execute on function public.my_seller_progress() from public, anon;
grant execute on function public.my_seller_progress() to authenticated;

-- Admin: the whole register with live totals (admins only, 2FA enforced by is_admin()).
create or replace function public.admin_seller_register()
returns table (
  seller_no bigint, seller_id uuid, shop_name text, username text, state text, city text,
  status public.register_status, status_reason text, id_status public.verification_status, bank_verified boolean,
  signed_up_at timestamptz, joined_at timestamptz, joined_is_estimate boolean,
  milestones jsonb, live_listings bigint, completed_orders bigint, completed_sales_kobo bigint,
  payouts_paid_kobo bigint, last_status_change timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can see the seller register' using errcode = '42501';
  end if;
  return query
  select r.seller_no, r.seller_id, r.shop_name, r.username, r.state, r.city, r.status, r.status_reason,
         r.id_status, r.bank_verified, r.signed_up_at, r.joined_at, r.joined_is_estimate,
         coalesce((select jsonb_object_agg(m.milestone, m.reached_at) from public.seller_milestones m where m.seller_no = r.seller_no), '{}'),
         (select count(*) from public.listings l where l.seller_id = r.seller_id and l.status = 'approved'),
         (select count(*) from public.orders o where o.seller_id = r.seller_id and o.status = 'completed'),
         coalesce((select sum(o.subtotal_kobo)::bigint from public.orders o where o.seller_id = r.seller_id and o.status = 'completed'), 0),
         coalesce((select sum(p.amount_kobo)::bigint from public.payouts p where p.seller_id = r.seller_id and p.status = 'paid'), 0),
         (select max(h.changed_at) from public.seller_status_history h where h.seller_no = r.seller_no)
  from public.seller_register r
  order by r.seller_no;
end $$;
revoke execute on function public.admin_seller_register() from public, anon;
grant execute on function public.admin_seller_register() to authenticated;

-- ---------------------------------------------------------------------
-- Backfill: sellers who joined before this record existed.
-- Dates come from real evidence where we have it; "became a seller" is
-- estimated from when they turned on 2FA (the step right before) and
-- marked as an estimate.
-- ---------------------------------------------------------------------
insert into public.seller_register (seller_id, shop_name, username, state, city, signed_up_at, joined_at,
                                    joined_is_estimate, status, status_reason, id_status, bank_verified)
select p.id, coalesce(p.business_name, p.display_name), p.username, p.state, p.city, p.created_at,
       coalesce((select min(f.created_at) from auth.mfa_factors f where f.user_id = p.id and f.status = 'verified'),
                (select min(l.created_at) from public.listings l where l.seller_id = p.id), p.created_at),
       true, private.register_status_of(p), p.status_reason,
       (select v.status from public.seller_verifications v where v.user_id = p.id),
       coalesce((select v.status = 'approved' and v.payment_recipient_code is not null from public.seller_verifications v where v.user_id = p.id), false)
from public.profiles p
where p.role in ('seller', 'admin')
  and not exists (select 1 from public.seller_register r where r.seller_id = p.id)
order by p.created_at;

insert into public.seller_status_history (seller_no, from_status, to_status, reason, changed_by, changed_at)
select r.seller_no, null, r.status, 'Existing seller added to the register', null, r.joined_at
from public.seller_register r
where not exists (select 1 from public.seller_status_history h where h.seller_no = r.seller_no);

insert into public.seller_milestones (seller_no, milestone, reached_at, source)
select r.seller_no, m.milestone, m.at, 'backfill'
from public.seller_register r
join public.profiles p on p.id = r.seller_id
cross join lateral (values
  ('signed_up'::public.seller_milestone, p.created_at),
  ('two_factor_on', (select min(f.created_at) from auth.mfa_factors f where f.user_id = p.id and f.status = 'verified')),
  ('shop_opened', r.joined_at),
  ('profile_completed', case when p.business_name is not null and p.headline is not null and p.bio is not null and p.state is not null then p.updated_at end),
  ('first_listing_approved', coalesce(
      (select min(e.at) from public.security_events e where e.action = 'listing_approved' and e.target_user = p.id),
      (select min(l.updated_at) from public.listings l where l.seller_id = p.id and l.status = 'approved'))),
  ('id_verified', (select v.reviewed_at from public.seller_verifications v where v.user_id = p.id and v.status = 'approved')),
  ('bank_verified', (select v.reviewed_at from public.seller_verifications v where v.user_id = p.id and v.status = 'approved' and v.payment_recipient_code is not null)),
  ('first_sale', (select min(o.created_at) from public.orders o where o.seller_id = p.id and o.status in ('paid','shipped','delivered','completed'))),
  ('first_payout', (select min(coalesce(po.paid_at, po.created_at)) from public.payouts po where po.seller_id = p.id and po.status = 'paid'))
) as m(milestone, at)
where m.at is not null
on conflict (seller_no, milestone) do nothing;

-- Data export: include the seller's own register entry and timeline.
do $$
declare d text;
begin
  d := pg_get_functiondef('public.export_my_data()'::regprocedure);
  d := replace(d, '''security_events_about_you'',',
    '''seller_record'', (select jsonb_build_object(''seller_number'', ''PS-'' || lpad(r.seller_no::text, 6, ''0''),
                           ''joined_at'', r.joined_at, ''status'', r.status,
                           ''timeline'', coalesce((select jsonb_object_agg(m.milestone, m.reached_at) from public.seller_milestones m where m.seller_no = r.seller_no), ''{}''),
                           ''status_history'', coalesce((select jsonb_agg(jsonb_build_object(''from'', h.from_status, ''to'', h.to_status, ''reason'', h.reason, ''at'', h.changed_at) order by h.changed_at)
                                                         from public.seller_status_history h where h.seller_no = r.seller_no), ''[]''))
                         from public.seller_register r where r.seller_id = uid),
    ''security_events_about_you'',');
  execute d;
end $$;
