-- =====================================================================
-- 011 · Privacy & data rights  (RECONSTRUCTED, Phase 1b W3, 2026-11-16)
-- ---------------------------------------------------------------------
-- The original 011 file was run by hand in the production SQL editor on
-- ~9-10 Nov 2026 and never committed. This file was rebuilt from the
-- production catalog (read-only capture, docs/schema/) so that a clean
-- database built from the repo matches production.
--
-- Where a later migration patches one of these functions by text
-- replacement (012, 016, 021, 022), this file contains the version
-- BEFORE those patches, so replaying 001→022 ends in production's state.
--
-- NEVER run this on production: production already has these objects.
-- Production history will only record it via `migration repair` (P1).
--
-- Contents
--   * pg_cron + pg_net extensions (012 uses cron.schedule; cleanup uses net.http_post)
--   * profiles.deletion_requested_at / deleted_at
--   * seller_verifications.id_document_deleted_at
--   * storage_deletion_queue (RLS on, no policies: service role only)
--   * queue_file_deletion, process_account_deletion, request_account_deletion,
--     cancel_account_deletion, export_my_data, run_privacy_retention
--   * cron: privacy-retention (02:15 daily), storage-cleanup (02:45 daily)
--
-- Environment requirement: Vault secret `project_url`
-- (e.g. https://<ref>.supabase.co) must exist before this runs, so the
-- storage-cleanup cron job calls THIS project's Edge Function. If it is
-- missing, the local Supabase URL is used (CI / local only).
-- =====================================================================

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- ---------- Columns ----------------------------------------------------
alter table public.profiles
  add column if not exists deletion_requested_at timestamptz,
  add column if not exists deleted_at timestamptz;
alter table public.seller_verifications
  add column if not exists id_document_deleted_at timestamptz;

-- ---------- Storage deletion queue ------------------------------------
-- Files can only be deleted through the Storage API, so the database
-- queues them and the storage-cleanup Edge Function deletes them nightly.
create table public.storage_deletion_queue (
  id          bigint generated always as identity primary key,
  bucket_id   text not null,
  object_name text not null,
  reason      text not null,
  queued_at   timestamptz not null default now(),
  done_at     timestamptz,
  last_error  text,
  unique (bucket_id, object_name)
);
alter table public.storage_deletion_queue enable row level security;

-- ---------- Functions --------------------------------------------------

create or replace function public.queue_file_deletion(p_bucket text, p_name text, p_reason text)
returns void language sql security definer set search_path = ''
as $function$
  insert into public.storage_deletion_queue (bucket_id, object_name, reason)
  values (p_bucket, p_name, p_reason)
  on conflict (bucket_id, object_name) do nothing;
$function$;

create or replace function public.process_account_deletion(uid uuid)
returns text language plpgsql security definer set search_path = ''
as $function$
declare
  has_money_history boolean;
  f record;
begin
  for f in select o.bucket_id, o.name from storage.objects o
           where o.bucket_id in ('id-documents', 'listing-images')
             and (storage.foldername(o.name))[1] = uid::text loop
    perform public.queue_file_deletion(f.bucket_id, f.name, 'account_deleted');
  end loop;

  has_money_history :=
       exists (select 1 from public.orders where uid in (buyer_id, seller_id))
    or exists (select 1 from public.checkouts where buyer_id = uid)
    or exists (select 1 from public.payouts where seller_id = uid)
    or exists (select 1 from public.bookings where uid in (buyer_id, pro_id))
    or exists (select 1 from public.disputes where opened_by = uid)
    or exists (select 1 from public.reseller_commissions where reseller_id = uid)
    or exists (select 1 from public.featured_purchases where seller_id = uid);

  if not has_money_history then
    delete from auth.users where id = uid;
    perform public.log_security_event('account_deleted', uid, 'profile', uid::text, '{"mode":"full"}');
    return 'deleted';
  end if;

  delete from public.listing_images where listing_id in (select id from public.listings where seller_id = uid);
  update public.listings set status = 'removed', title = 'Removed listing', description = '',
         city = null, state = null, featured_until = null
  where seller_id = uid;
  delete from public.saves where user_id = uid;
  delete from public.cart_items where user_id = uid;
  delete from public.follows where uid in (follower_id, seller_id);
  delete from public.notifications where recipient_id = uid;
  delete from public.service_areas where seller_id = uid;
  delete from public.working_hours where seller_id = uid;
  update public.buyer_requests set title = 'Removed request', description = '', city = null, state = null, status = 'closed'
  where buyer_id = uid;
  update public.request_offers set message = '' where seller_id = uid;
  update public.messages set body = '[message deleted]' where sender_id = uid;
  update public.reviews set body = null where reviewer_id = uid;
  update public.reviews set seller_reply = null where seller_id = uid;
  update public.checkouts set delivery_name = null, delivery_phone = null, delivery_address = null where buyer_id = uid;
  update public.bookings set service_address = null, job_details = null where buyer_id = uid;
  update public.seller_verifications
  set bank_name = null, account_name = null, account_last4 = null, payment_recipient_code = null,
      id_document_deleted_at = coalesce(id_document_deleted_at, now())
  where user_id = uid;
  update public.profiles
  set display_name = 'Deleted user', username = 'deleted_' || substr(replace(uid::text, '-', ''), 1, 12),
      bio = null, avatar_url = null, city = null, state = null, business_name = null, headline = null,
      years_experience = null, is_available = false,
      account_status = 'banned', status_reason = 'Account deleted at the user''s request',
      deleted_at = now()
  where id = uid;

  delete from auth.sessions where user_id = uid;
  delete from auth.identities where user_id = uid;
  delete from auth.mfa_factors where user_id = uid;
  update auth.users
  set email = 'deleted+' || replace(uid::text, '-', '') || '@deleted.invalid',
      phone = null, encrypted_password = null, raw_user_meta_data = '{}'::jsonb,
      banned_until = now() + interval '100 years'
  where id = uid;

  perform public.log_security_event('account_deleted', uid, 'profile', uid::text, '{"mode":"anonymised"}');
  return 'anonymised';
end $function$;

create or replace function public.request_account_deletion(confirm_username text)
returns timestamp with time zone language plpgsql security definer set search_path = ''
as $function$
declare
  uid uuid := auth.uid();
  p record;
begin
  if uid is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  select * into p from public.profiles where id = uid;
  if lower(trim(confirm_username)) is distinct from lower(p.username) then
    raise exception 'Type your username exactly to confirm' using errcode = '22023';
  end if;
  if exists (select 1 from auth.mfa_factors f where f.user_id = uid and f.status = 'verified')
     and not public.has_aal2() then
    raise exception 'Confirm with your authenticator code first' using errcode = '42501';
  end if;
  if exists (select 1 from public.orders o where uid in (o.buyer_id, o.seller_id)
             and o.status in ('paid', 'shipped', 'delivered', 'disputed')) then
    raise exception 'You have orders still in progress. Finish or cancel them first, then try again.' using errcode = '55000';
  end if;
  if exists (select 1 from public.bookings b where uid in (b.buyer_id, b.pro_id)
             and b.status in ('requested', 'accepted', 'scheduled', 'in_progress')) then
    raise exception 'You have bookings still in progress. Finish or cancel them first, then try again.' using errcode = '55000';
  end if;

  update public.profiles set deletion_requested_at = now() where id = uid;
  perform public.log_security_event('deletion_requested', uid, 'profile', uid::text);
  return now() + interval '30 days';
end $function$;

create or replace function public.cancel_account_deletion()
returns void language plpgsql security definer set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  update public.profiles set deletion_requested_at = null
  where id = auth.uid() and deletion_requested_at is not null and deleted_at is null;
  if found then
    perform public.log_security_event('deletion_cancelled', auth.uid(), 'profile', auth.uid()::text);
  end if;
end $function$;

create or replace function public.export_my_data()
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  uid uuid := auth.uid();
  result jsonb;
begin
  if uid is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  if (select count(*) from public.security_events
      where actor_id = uid and action = 'data_exported' and at > now() - interval '24 hours') >= 5 then
    raise exception 'You can download your data 5 times a day. Please try again tomorrow.' using errcode = '54000';
  end if;

  select jsonb_build_object(
    'about_this_file', 'Everything Purple Vendra holds about you, as of the time below. Prices are in kobo (100 kobo = 1 naira).',
    'exported_at', now(),
    'account', (select jsonb_build_object('email', u.email, 'phone', u.phone, 'created_at', u.created_at,
                                          'last_sign_in_at', u.last_sign_in_at)
                from auth.users u where u.id = uid),
    'two_factor_methods', coalesce((select jsonb_agg(jsonb_build_object('type', f.factor_type, 'name', f.friendly_name,
                                          'status', f.status, 'created_at', f.created_at))
                from auth.mfa_factors f where f.user_id = uid), '[]'),
    'profile', (select to_jsonb(p) from public.profiles p where p.id = uid),
    'seller_verification', (select jsonb_build_object('status', v.status, 'id_type', v.id_type,
                              'submitted_at', v.submitted_at, 'reviewed_at', v.reviewed_at,
                              'rejection_reason', v.rejection_reason, 'id_file_on_record', v.id_document_deleted_at is null,
                              'id_file_deleted_at', v.id_document_deleted_at, 'bank_name', v.bank_name,
                              'account_name', v.account_name, 'account_last4', v.account_last4)
                from public.seller_verifications v where v.user_id = uid),
    'listings', coalesce((select jsonb_agg(to_jsonb(l) - 'search') from public.listings l where l.seller_id = uid), '[]'),
    'listing_photos', coalesce((select jsonb_agg(to_jsonb(i)) from public.listing_images i
                                join public.listings l on l.id = i.listing_id where l.seller_id = uid), '[]'),
    'saved_items', coalesce((select jsonb_agg(to_jsonb(s)) from public.saves s where s.user_id = uid), '[]'),
    'cart', coalesce((select jsonb_agg(to_jsonb(c)) from public.cart_items c where c.user_id = uid), '[]'),
    'following', coalesce((select jsonb_agg(jsonb_build_object('seller', p.username, 'since', f.created_at))
                           from public.follows f join public.profiles p on p.id = f.seller_id
                           where f.follower_id = uid), '[]'),
    'followers_count', (select count(*) from public.follows f where f.seller_id = uid),
    'buyer_requests', coalesce((select jsonb_agg(to_jsonb(r)) from public.buyer_requests r where r.buyer_id = uid), '[]'),
    'quotes_sent', coalesce((select jsonb_agg(to_jsonb(o)) from public.request_offers o where o.seller_id = uid), '[]'),
    'checkouts', coalesce((select jsonb_agg(to_jsonb(c)) from public.checkouts c where c.buyer_id = uid), '[]'),
    'orders_as_buyer', coalesce((select jsonb_agg(to_jsonb(o)) from public.orders o where o.buyer_id = uid), '[]'),
    'orders_as_seller', coalesce((select jsonb_agg(to_jsonb(o)) from public.orders o where o.seller_id = uid), '[]'),
    'bookings_as_buyer', coalesce((select jsonb_agg(to_jsonb(b)) from public.bookings b where b.buyer_id = uid), '[]'),
    'bookings_as_pro', coalesce((select jsonb_agg(to_jsonb(b) - 'service_address') from public.bookings b where b.pro_id = uid), '[]'),
    'payouts', coalesce((select jsonb_agg(to_jsonb(p)) from public.payouts p where p.seller_id = uid), '[]'),
    'reseller_commissions', coalesce((select jsonb_agg(to_jsonb(c)) from public.reseller_commissions c where c.reseller_id = uid), '[]'),
    'disputes_opened', coalesce((select jsonb_agg(to_jsonb(d) - 'resolved_by') from public.disputes d where d.opened_by = uid), '[]'),
    'reviews_written', coalesce((select jsonb_agg(to_jsonb(r) - 'hidden_by') from public.reviews r where r.reviewer_id = uid), '[]'),
    'reviews_received', coalesce((select jsonb_agg(jsonb_build_object('rating', r.rating, 'body', r.body,
                           'your_reply', r.seller_reply, 'created_at', r.created_at, 'hidden', r.is_hidden))
                           from public.reviews r where r.seller_id = uid), '[]'),
    'conversations', coalesce((select jsonb_agg(jsonb_build_object(
                           'conversation_id', c.id, 'you_are', case when c.buyer_id = uid then 'buyer' else 'seller' end,
                           'messages', coalesce((select jsonb_agg(jsonb_build_object(
                               'from', case when m.sender_id = uid then 'you' else 'the other person' end,
                               'body', m.body, 'sent_at', m.created_at) order by m.created_at)
                             from public.messages m where m.conversation_id = c.id), '[]')))
                           from public.conversations c where uid in (c.buyer_id, c.seller_id)), '[]'),
    'notifications', coalesce((select jsonb_agg(to_jsonb(n)) from public.notifications n where n.recipient_id = uid), '[]'),
    'reports_you_sent', coalesce((select jsonb_agg(jsonb_build_object('reason', r.reason, 'details', r.details,
                           'listing_id', r.listing_id, 'status', r.status, 'created_at', r.created_at))
                           from public.reports r where r.reporter_id = uid), '[]'),
    'referrals', coalesce((select jsonb_agg(to_jsonb(r)) from public.referrals r where uid in (r.referrer_id, r.referred_id)), '[]'),
    'share_links', coalesce((select jsonb_agg(to_jsonb(s)) from public.share_links s where s.created_by = uid), '[]'),
    'security_events_about_you', coalesce((select jsonb_agg(jsonb_build_object('action', e.action, 'at', e.at) order by e.at)
                           from public.security_events e where e.target_user = uid), '[]')
  ) into result;

  perform public.log_security_event('data_exported', uid, 'profile', uid::text);
  return result;
end $function$;

create or replace function public.run_privacy_retention()
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  n_deleted int := 0; n_ids int := 0; n_extra_ids int := 0; n_checkouts int := 0; n_bookings int := 0;
  n_messages int := 0; n_notifications int := 0; n_reports int := 0; n_flags int := 0; n_log int := 0;
  u record; v record; f record;
  summary jsonb;
begin
  for u in select id from public.profiles
           where deletion_requested_at < now() - interval '30 days' and deleted_at is null loop
    perform public.process_account_deletion(u.id);
    n_deleted := n_deleted + 1;
  end loop;

  for v in select sv.user_id, sv.id_document_path from public.seller_verifications sv
           join public.profiles p on p.id = sv.user_id
           where sv.id_document_deleted_at is null and sv.id_document_path is not null
             and ((sv.status = 'approved' and sv.reviewed_at < now() - interval '180 days')
               or (sv.status = 'rejected' and sv.reviewed_at < now() - interval '30 days'))
             and p.account_status = 'active'
             and not exists (select 1 from public.risk_flags rf where rf.user_id = sv.user_id and rf.status = 'open') loop
    perform public.queue_file_deletion('id-documents', v.id_document_path, 'id_retention');
    update public.seller_verifications set id_document_deleted_at = now() where user_id = v.user_id;
    n_ids := n_ids + 1;
  end loop;

  for f in select o.name from storage.objects o
           where o.bucket_id = 'id-documents' and o.created_at < now() - interval '30 days'
             and not exists (select 1 from public.seller_verifications sv
                             where sv.id_document_path = o.name and sv.id_document_deleted_at is null) loop
    perform public.queue_file_deletion('id-documents', f.name, 'replaced_upload');
    n_extra_ids := n_extra_ids + 1;
  end loop;

  with done as (
    update public.checkouts c
    set delivery_name = null, delivery_phone = null, delivery_address = null
    where c.delivery_phone is not null
      and (
        (c.status in ('failed', 'abandoned') and c.created_at < now() - interval '30 days')
        or (c.status = 'paid'
            and not exists (select 1 from public.orders o where o.checkout_id = c.id
                            and (o.status in ('paid', 'shipped', 'delivered', 'disputed')
                                 or greatest(o.created_at, o.delivered_at, o.completed_at) > now() - interval '90 days')))
      )
    returning 1)
  select count(*) into n_checkouts from done;

  with done as (
    update public.bookings set service_address = null, job_details = null
    where service_address is not null
      and status in ('completed', 'cancelled', 'declined') and updated_at < now() - interval '90 days'
    returning 1)
  select count(*) into n_bookings from done;

  with done as (delete from public.messages where created_at < now() - interval '2 years' returning 1)
  select count(*) into n_messages from done;
  with done as (
    delete from public.notifications
    where (read_at is not null and read_at < now() - interval '6 months') or created_at < now() - interval '1 year'
    returning 1)
  select count(*) into n_notifications from done;

  with done as (delete from public.reports where status <> 'open' and created_at < now() - interval '2 years' returning 1)
  select count(*) into n_reports from done;
  with done as (delete from public.risk_flags where status <> 'open' and created_at < now() - interval '1 year' returning 1)
  select count(*) into n_flags from done;

  perform set_config('pv.allow_audit_purge', 'on', true);
  with done as (delete from public.security_events where at < now() - interval '2 years' returning 1)
  select count(*) into n_log from done;
  perform set_config('pv.allow_audit_purge', 'off', true);

  summary := jsonb_build_object(
    'accounts_deleted', n_deleted, 'id_files_retired', n_ids, 'replaced_id_files', n_extra_ids,
    'delivery_details_cleared', n_checkouts, 'booking_addresses_cleared', n_bookings,
    'messages_deleted', n_messages, 'notifications_deleted', n_notifications,
    'old_reports_deleted', n_reports, 'old_flags_deleted', n_flags, 'old_log_entries_deleted', n_log);
  perform public.log_security_event('retention_run', null, null, null, summary);
  return summary;
end $function$;


-- ---------- Function access -------------------------------------------
-- Signed-in users may request, cancel and export; the rest is internal.
revoke execute on function public.request_account_deletion(text), public.cancel_account_deletion(),
  public.export_my_data()
  from public, anon;
grant execute on function public.request_account_deletion(text), public.cancel_account_deletion(),
  public.export_my_data()
  to authenticated;
revoke execute on function public.queue_file_deletion(text, text, text), public.process_account_deletion(uuid),
  public.run_privacy_retention()
  from public, anon, authenticated;

-- ---------- Scheduled jobs ---------------------------------------------
select cron.schedule('privacy-retention', '15 2 * * *', 'select public.run_privacy_retention()');

do $$
declare
  base text := coalesce(
    (select decrypted_secret from vault.decrypted_secrets where name = 'project_url'),
    'http://127.0.0.1:54321');
begin
  perform cron.schedule('storage-cleanup', '45 2 * * *', format($cmd$
  select net.http_post(
    url := '%s/functions/v1/storage-cleanup',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb)
$cmd$, base));
end $$;
