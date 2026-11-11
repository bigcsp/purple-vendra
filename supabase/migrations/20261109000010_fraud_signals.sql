-- =====================================================================
-- Purple Vendra — safety layer 2: fraud and abuse signals (9 Nov 2026)
--
-- * Reports: users report a listing or a person. Limits stop abuse of
--   reporting itself. 3 different established users reporting the same
--   listing hides it until an admin reviews it.
-- * risk_flags: automatic warning signs raised for an admin to review.
--   Flags never punish anyone on their own; a person decides.
--     off_platform_contact  phone / WhatsApp / bank details in a listing or message
--     price_too_low         price under 20% of the category's usual price
--     listing_burst         account under 7 days old posting 10+ listings in 24h
--     listing_reported      listing reported by 3+ different users
--     reported_user         person reported by 3+ different users in 30 days
--     dispute_pattern       seller with 3+ disputes in 30 days
--     buyer_dispute_pattern buyer opening 3+ disputes in 30 days
-- * Hard limit: 30 new listings per seller per 24 hours.
-- * Admin review queue + resolve/dismiss actions, all logged.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Risk flags
-- ---------------------------------------------------------------------
create table public.risk_flags (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null,
  severity     text not null check (severity in ('low', 'medium', 'high')),
  user_id      uuid references public.profiles (id) on delete cascade,
  listing_id   uuid references public.listings (id) on delete cascade,
  ref_type     text,            -- extra context, e.g. 'message', 'order'
  ref_id       text,
  details      jsonb not null default '{}',
  status       text not null default 'open' check (status in ('open', 'reviewed', 'dismissed')),
  review_note  text,
  reviewed_by  uuid references public.profiles (id),
  reviewed_at  timestamptz,
  created_at   timestamptz not null default now()
);
create index risk_flags_open_idx on public.risk_flags (created_at desc) where status = 'open';
create index risk_flags_user_idx on public.risk_flags (user_id, created_at desc);
-- One open flag per kind per person per listing (repeats update nothing).
create unique index risk_flags_one_open
  on public.risk_flags (kind, user_id, listing_id) nulls not distinct
  where status = 'open';

alter table public.risk_flags enable row level security;

create policy "Admins see risk flags"
  on public.risk_flags for select to authenticated
  using ((select public.is_admin()));

-- Internal: raise a flag unless the same one is already open.
create or replace function public.raise_flag(
  p_kind text, p_severity text, p_user uuid, p_listing uuid default null,
  p_ref_type text default null, p_ref_id text default null, p_details jsonb default '{}'
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.risk_flags (kind, severity, user_id, listing_id, ref_type, ref_id, details)
  values (p_kind, p_severity, p_user, p_listing, p_ref_type, p_ref_id, coalesce(p_details, '{}'))
  on conflict (kind, user_id, listing_id) where status = 'open' do nothing;
end $$;
revoke execute on function public.raise_flag(text, text, uuid, uuid, text, text, jsonb) from public, anon, authenticated;

-- Detects phone numbers, WhatsApp/Telegram links, and bank-transfer
-- requests: the usual ways scammers move a buyer off the platform.
create or replace function public.looks_like_off_platform(t text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(
       regexp_replace(t, '[\s\-\.\(\)]', '', 'g') ~ '(\+?234|0)[789][01][0-9]{8}'
    or regexp_replace(t, '[\s\-\.]', '', 'g') ~ '(^|[^0-9])[0-9]{10}([^0-9]|$)'
    or t ~* '(whats\s*app|wa\.me|telegram|t\.me/|call\s*me\s*on|dm\s*me\s*on)'
    or t ~* '(account\s*(no|num|number)|acct\s*no|bank\s*transfer|pay\s*(directly|to\s*my|into\s*my)|send\s*(the\s*)?money\s*to)',
    false);
$$;

-- ---------------------------------------------------------------------
-- Listings: hard daily cap + automatic flags
-- ---------------------------------------------------------------------
create or replace function public.enforce_listing_rate() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() and (
    select count(*) from public.listings
    where seller_id = new.seller_id and created_at > now() - interval '24 hours'
  ) >= 30 then
    raise exception 'Daily limit reached: 30 new listings per day. Try again tomorrow.' using errcode = '54000';
  end if;
  return new;
end $$;
revoke execute on function public.enforce_listing_rate() from public, anon, authenticated;

create trigger listings_rate_limit
  before insert on public.listings
  for each row execute function public.enforce_listing_rate();

create or replace function public.check_listing_risk() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  median_price numeric;
  peers        int;
  recent       int;
  account_age  interval;
begin
  -- Contact or bank details in the title or description.
  if (tg_op = 'INSERT' or new.title is distinct from old.title or new.description is distinct from old.description)
     and public.looks_like_off_platform(new.title || ' ' || new.description) then
    perform public.raise_flag('off_platform_contact', 'medium', new.seller_id, new.id, 'listing', new.id::text,
      jsonb_build_object('title', new.title));
  end if;

  -- Price far below the category's usual price.
  if (tg_op = 'INSERT' or new.price_kobo is distinct from old.price_kobo or new.category_id is distinct from old.category_id)
     and not new.quote_on_request then
    select percentile_cont(0.5) within group (order by l.price_kobo), count(*)
    into median_price, peers
    from public.listings l
    where l.category_id = new.category_id and l.status = 'approved' and l.type = new.type and l.id <> new.id;
    if peers >= 5 and new.price_kobo < median_price * 0.2 then
      perform public.raise_flag('price_too_low', 'medium', new.seller_id, new.id, 'listing', new.id::text,
        jsonb_build_object('price_kobo', new.price_kobo, 'category_median_kobo', round(median_price)));
    end if;
  end if;

  -- Brand-new account posting a burst of listings.
  if tg_op = 'INSERT' then
    select now() - p.created_at into account_age from public.profiles p where p.id = new.seller_id;
    select count(*) into recent from public.listings
    where seller_id = new.seller_id and created_at > now() - interval '24 hours';
    if account_age < interval '7 days' and recent >= 10 then
      perform public.raise_flag('listing_burst', 'medium', new.seller_id, null, null, null,
        jsonb_build_object('listings_24h', recent, 'account_age_days', extract(day from account_age)));
    end if;
  end if;
  return null;
end $$;
revoke execute on function public.check_listing_risk() from public, anon, authenticated;

create trigger listings_risk_check
  after insert or update of title, description, price_kobo, category_id on public.listings
  for each row execute function public.check_listing_risk();

-- ---------------------------------------------------------------------
-- Messages and disputes: automatic flags
-- ---------------------------------------------------------------------
create or replace function public.check_message_risk() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  is_seller boolean;
begin
  -- Sellers pushing buyers to pay outside escrow is the main scam pattern.
  select exists (select 1 from public.conversations c where c.id = new.conversation_id and c.seller_id = new.sender_id)
  into is_seller;
  if public.looks_like_off_platform(new.body) then
    perform public.raise_flag('off_platform_contact', case when is_seller then 'medium' else 'low' end,
      new.sender_id, null, 'message', new.id::text,
      jsonb_build_object('conversation_id', new.conversation_id, 'sender_is_seller', is_seller));
  end if;
  return null;
end $$;
revoke execute on function public.check_message_risk() from public, anon, authenticated;

create trigger messages_risk_check
  after insert on public.messages
  for each row execute function public.check_message_risk();

create or replace function public.check_dispute_risk() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  o record;
  n int;
begin
  select seller_id, buyer_id into o from public.orders where id = new.order_id;

  select count(*) into n from public.disputes d join public.orders ord on ord.id = d.order_id
  where ord.seller_id = o.seller_id and d.created_at > now() - interval '30 days';
  if n >= 3 then
    perform public.raise_flag('dispute_pattern', 'high', o.seller_id, null, 'dispute', new.id::text,
      jsonb_build_object('disputes_30d', n));
  end if;

  select count(*) into n from public.disputes d
  where d.opened_by = new.opened_by and d.created_at > now() - interval '30 days';
  if n >= 3 and new.opened_by = o.buyer_id then
    perform public.raise_flag('buyer_dispute_pattern', 'medium', new.opened_by, null, 'dispute', new.id::text,
      jsonb_build_object('disputes_opened_30d', n));
  end if;
  return null;
end $$;
revoke execute on function public.check_dispute_risk() from public, anon, authenticated;

create trigger disputes_risk_check
  after insert on public.disputes
  for each row execute function public.check_dispute_risk();

-- ---------------------------------------------------------------------
-- Reports
-- ---------------------------------------------------------------------
alter table public.reports
  add constraint reports_reason_check check (reason in
    ('scam', 'counterfeit', 'prohibited_item', 'misleading', 'harassment', 'fake_profile', 'off_platform_payment', 'other')),
  add constraint reports_has_target check (listing_id is not null or reported_user_id is not null),
  add column resolution_note text,
  add column handled_at      timestamptz;

create unique index reports_one_open_per_target
  on public.reports (reporter_id, listing_id, reported_user_id) nulls not distinct
  where status = 'open';

-- How many reports the signed-in user sent in the last 24 hours.
create or replace function public.reports_sent_today() returns bigint
language sql stable security definer set search_path = '' as $$
  select count(*) from public.reports where reporter_id = auth.uid() and created_at > now() - interval '24 hours';
$$;
revoke execute on function public.reports_sent_today() from public, anon;
grant  execute on function public.reports_sent_today() to authenticated;

-- Looks up a listing's seller even when the listing isn't public.
create or replace function public.listing_seller(p_listing uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select seller_id from public.listings where id = p_listing;
$$;
revoke execute on function public.listing_seller(uuid) from public, anon;
grant  execute on function public.listing_seller(uuid) to authenticated;

-- Runs with the reporter's own permissions (NOT elevated), so it can
-- tell an ordinary user's report from the SQL editor or an admin.
create or replace function public.protect_report() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.listing_id is not null then
    new.reported_user_id := public.listing_seller(new.listing_id);
    if new.reported_user_id is null then
      raise exception 'That listing no longer exists' using errcode = 'P0002';
    end if;
  end if;

  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.reporter_id is distinct from auth.uid() then
      raise exception 'You can only send reports as yourself' using errcode = '42501';
    end if;
    if new.reported_user_id = auth.uid() then
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

create trigger reports_protect
  before insert on public.reports
  for each row execute function public.protect_report();

-- After a report: hide a listing reported by 3 established users, and
-- flag people reported by 3 different users.
create or replace function public.escalate_report() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  perform public.log_security_event('report_filed', new.reported_user_id, 'report', new.id::text,
    jsonb_build_object('reason', new.reason, 'listing_id', new.listing_id));

  if new.listing_id is not null then
    select count(distinct r.reporter_id) into n
    from public.reports r join public.profiles p on p.id = r.reporter_id
    where r.listing_id = new.listing_id and r.status = 'open'
      and p.created_at < now() - interval '3 days';
    if n >= 3 then
      update public.listings set status = 'pending'
      where id = new.listing_id and status = 'approved';
      if found then
        perform public.log_security_event('listing_auto_hidden', new.reported_user_id, 'listing', new.listing_id::text,
          jsonb_build_object('open_reports', n));
      end if;
      perform public.raise_flag('listing_reported', 'high', new.reported_user_id, new.listing_id, null, null,
        jsonb_build_object('reporters', n));
    end if;
  end if;

  select count(distinct reporter_id) into n from public.reports
  where reported_user_id = new.reported_user_id and created_at > now() - interval '30 days';
  if n >= 3 then
    perform public.raise_flag('reported_user', 'high', new.reported_user_id, null, null, null,
      jsonb_build_object('reporters_30d', n));
  end if;
  return null;
end $$;
revoke execute on function public.escalate_report() from public, anon, authenticated;

create trigger reports_escalate
  after insert on public.reports
  for each row execute function public.escalate_report();

create policy "Users can send reports"
  on public.reports for insert to authenticated
  with check (reporter_id = (select auth.uid()));

create policy "Users see the reports they sent"
  on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()));

create policy "Admins see all reports"
  on public.reports for select to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------
-- Admin review queue and actions
-- ---------------------------------------------------------------------
create or replace function public.admin_review_queue()
returns table (item_type text, item_id text, severity text, kind text, user_id uuid,
               username text, listing_id uuid, summary text, created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can do this' using errcode = '42501';
  end if;
  return query
  select q.* from (
    select 'flag'::text as item_type, f.id::text as item_id, f.severity, f.kind, f.user_id, p.username,
           f.listing_id, f.details::text as summary, f.created_at
    from public.risk_flags f left join public.profiles p on p.id = f.user_id
    where f.status = 'open'
    union all
    select 'report', r.id::text,
           case when r.reason in ('scam', 'off_platform_payment', 'counterfeit') then 'high' else 'medium' end,
           r.reason, r.reported_user_id, p.username, r.listing_id,
           coalesce(r.details, ''), r.created_at
    from public.reports r left join public.profiles p on p.id = r.reported_user_id
    where r.status = 'open'
    union all
    select 'id_check', v.user_id::text, 'low', coalesce(v.id_type, 'id'), v.user_id, p.username, null::uuid,
           'ID waiting for review', v.submitted_at
    from public.seller_verifications v join public.profiles p on p.id = v.user_id
    where v.status = 'pending'
  ) q
  order by case q.severity when 'high' then 0 when 'medium' then 1 else 2 end, q.created_at;
end $$;
revoke execute on function public.admin_review_queue() from public, anon;
grant  execute on function public.admin_review_queue() to authenticated;

create or replace function public.admin_resolve_report(p_report uuid, p_outcome public.report_status, p_note text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  r record;
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can do this' using errcode = '42501';
  end if;
  if p_outcome = 'open' then
    raise exception 'Choose actioned or dismissed' using errcode = '22023';
  end if;
  update public.reports
  set status = p_outcome, handled_by = auth.uid(), handled_at = now(), resolution_note = p_note
  where id = p_report
  returning * into r;
  if not found then
    raise exception 'No such report' using errcode = 'P0002';
  end if;
  perform public.log_security_event('report_' || p_outcome::text, r.reported_user_id, 'report', r.id::text,
    jsonb_build_object('note', p_note));
end $$;
revoke execute on function public.admin_resolve_report(uuid, public.report_status, text) from public, anon;
grant  execute on function public.admin_resolve_report(uuid, public.report_status, text) to authenticated;

create or replace function public.admin_review_flag(p_flag uuid, p_outcome text, p_note text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  f record;
begin
  if not public.is_admin() then
    raise exception 'Only admins signed in with 2FA can do this' using errcode = '42501';
  end if;
  if p_outcome not in ('reviewed', 'dismissed') then
    raise exception 'Choose reviewed or dismissed' using errcode = '22023';
  end if;
  update public.risk_flags
  set status = p_outcome, review_note = p_note, reviewed_by = auth.uid(), reviewed_at = now()
  where id = p_flag
  returning * into f;
  if not found then
    raise exception 'No such flag' using errcode = 'P0002';
  end if;
  perform public.log_security_event('flag_' || p_outcome, f.user_id, 'risk_flag', f.id::text,
    jsonb_build_object('kind', f.kind, 'note', p_note));
end $$;
revoke execute on function public.admin_review_flag(uuid, text, text) from public, anon;
grant  execute on function public.admin_review_flag(uuid, text, text) to authenticated;
