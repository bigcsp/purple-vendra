-- =====================================================================
-- Purple Shop anonymizer (W6). STAGING / LOCAL COPIES ONLY.
--
-- Replaces personal data in a copy of the database with deterministic
-- pseudonyms, so a copy can be used for testing without exposing anyone.
-- Same input always gives the same output (pseudonyms come from md5 of
-- the row id), so it is safe to run twice.
--
-- It creates no tables, functions or other objects. It runs as one DO block.
--
-- Guard: you must name the target project, and it must match this
-- database's Vault `project_url`; production is always refused.
--   set purple.anonymize_target = '<project ref>';   -- e.g. fwyviexwregngnqtwcra
--   \i supabase/tools/anonymize.sql
--
-- What changes and what is kept: docs/W6-SEED-AND-ANONYMIZER.md §3.
-- =====================================================================
do $anonymize$
declare
  prod_ref constant text := 'nozxxxldfthbwhjwbsmy';
  target   text := nullif(current_setting('purple.anonymize_target', true), '');
  here     text;
begin
  select decrypted_secret into here from vault.decrypted_secrets where name = 'project_url';
  if target is null then
    raise exception 'anonymize refused: set purple.anonymize_target to this project''s ref first';
  end if;
  if target = prod_ref or coalesce(here, '') like '%' || prod_ref || '%' then
    raise exception 'anonymize refused: production is never anonymized in place';
  end if;
  if here is null or here not like '%' || target || '%' then
    raise exception 'anonymize refused: target % does not match this database (%)', target, coalesce(here, 'no project_url');
  end if;

  -- Audit and review triggers block edits on purpose; pause them for this transaction only.
  alter table public.reviews disable trigger reviews_protect;
  alter table public.security_events disable trigger security_events_append_only;

  -- 1. Sign-in data
  update auth.users u set
    email = 'user-' || left(md5(u.id::text), 12) || '@anon.purple.test',
    phone = null,
    raw_user_meta_data = jsonb_build_object('username', 'user_' || left(md5(u.id::text), 10),
                                            'display_name', 'Member ' || left(md5(u.id::text), 6)),
    encrypted_password = extensions.crypt(encode(extensions.gen_random_bytes(24), 'hex'), extensions.gen_salt('bf', 4)),
    email_change = '', email_change_token_new = '', email_change_token_current = '',
    confirmation_token = '', recovery_token = '', reauthentication_token = '', phone_change = '', phone_change_token = '';
  update auth.identities i set
    identity_data = jsonb_build_object('sub', i.user_id::text, 'email', 'user-' || left(md5(i.user_id::text), 12) || '@anon.purple.test',
                                       'email_verified', true, 'phone_verified', false)
  where i.provider = 'email';
  delete from auth.identities where provider <> 'email';
  delete from auth.mfa_factors;
  delete from auth.sessions;
  delete from auth.refresh_tokens;
  delete from auth.one_time_tokens;
  delete from auth.flow_state;
  delete from auth.audit_log_entries;

  -- 2. Profiles (the seller register snapshot follows via its trigger; set explicitly below as well)
  update public.profiles p set
    display_name  = case when p.role = 'buyer' then 'Member ' else 'Seller ' end || left(md5(p.id::text), 6),
    username      = 'user_' || left(md5(p.id::text), 10),
    business_name = case when p.business_name is not null then 'Shop ' || left(md5(p.id::text), 6) end,
    headline      = case when p.headline is not null then 'Anonymised headline' end,
    bio           = case when p.bio is not null then 'Anonymised profile text.' end,
    avatar_url    = null,
    cover_url     = null,
    status_reason = case when p.status_reason is not null then 'Anonymised reason' end;
  update public.seller_register r set
    shop_name = case when r.anonymised_at is not null then r.shop_name
                     else coalesce('Shop ' || left(md5(r.seller_id::text), 6), 'Deleted seller #' || r.seller_no) end,
    username  = case when r.seller_id is not null and r.anonymised_at is null then 'user_' || left(md5(r.seller_id::text), 10) end,
    status_reason = case when r.status_reason is not null then 'Anonymised reason' end;
  update public.seller_status_history set reason = 'Anonymised reason' where reason is not null;
  update public.pro_entries set organisation = case when organisation is not null then 'Organisation' end,
                                location = null, description = null;

  -- 3. Identity and bank details
  update public.seller_verifications set
    id_document_path = null,
    id_document_deleted_at = coalesce(id_document_deleted_at, now()),
    account_name = 'Account holder', account_last4 = '0000',
    bank_code = null, payment_recipient_code = null;

  -- 4. Addresses, phone numbers and payment references
  update public.checkouts set
    delivery_name    = case when delivery_name is not null then 'Recipient' end,
    delivery_phone   = case when delivery_phone is not null then '+2340000000000' end,
    delivery_address = case when delivery_address is not null then 'Anonymised address' end,
    payment_reference = case when payment_reference is not null then 'ANON-' || left(md5(id::text), 20) end;
  update public.payouts set transfer_reference = 'ANON-' || left(md5(id::text), 20) where transfer_reference is not null;
  update public.featured_purchases set payment_reference = 'ANON-' || left(md5(id::text), 20) where payment_reference is not null;
  update public.story_campaigns set payment_reference = case when payment_reference is not null then 'ANON-' || left(md5(id::text), 20) end,
                                    audience_note = null, admin_note = null;
  update public.bookings set job_details = 'Anonymised job details.', service_address = 'Anonymised address';

  -- 5. Private conversations and free text written by people
  update public.messages set body = 'Anonymised message.';
  update public.story_comments set body = 'Anonymised comment.';
  update public.reviews set body = case when body is not null then 'Anonymised review.' end,
                            seller_reply = case when seller_reply is not null then 'Anonymised reply.' end;
  update public.request_offers set message = 'Anonymised offer message.';
  update public.buyer_requests set description = 'Anonymised request details.';
  update public.reports set details = case when details is not null then 'Anonymised report.' end,
                            resolution_note = case when resolution_note is not null then 'Anonymised note.' end;
  update public.disputes set details = case when details is not null then 'Anonymised dispute.' end,
                             resolution_note = case when resolution_note is not null then 'Anonymised note.' end;
  update public.notifications set title = 'Notification', body = null;
  update public.content_features set url = null;

  -- 6. Logs that can hold personal details
  update public.security_events set details = jsonb_build_object('anonymised', true) where details is not null;
  update public.risk_flags set details = jsonb_build_object('anonymised', true), review_note = null;

  alter table public.reviews enable trigger reviews_protect;
  alter table public.security_events enable trigger security_events_append_only;

  raise notice 'anonymize: done for %', target;
end $anonymize$;
