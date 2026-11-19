-- =====================================================================
-- Purple Shop anonymizer (W6). STAGING / LOCAL COPIES ONLY.
--
-- Replaces personal data in a COPY of the database with deterministic
-- pseudonyms, so the copy can be used for testing without exposing anyone.
-- Same input always gives the same output (pseudonyms come from md5 of the
-- row id), so running it twice gives the same result.
--
-- It creates no tables, functions or other objects. It is ONE statement (a
-- single DO block), so it either finishes completely or changes nothing.
--
-- WARNING: run this file as a whole (psql -f / \i, or paste the whole file).
-- Never copy individual statements out of it: it switches off three
-- protective triggers for the duration of its own transaction, and that is
-- only safe because the switch-off is undone automatically if anything fails.
-- While it runs it holds exclusive locks on reviews, security_events and
-- seller_status_history; run it on a copy nobody else is using.
--
-- Guard (allowlist, fails closed). Name the target first:
--   staging copy:  set purple.anonymize_target = '<approved staging ref>';
--   local copy:    set purple.anonymize_target = 'local';
-- The target must exactly match this database's Vault project_url (a local
-- address for 'local'). Production, a missing or unreadable project_url, or
-- any mismatch stops it before anything changes.
--
-- Files in Storage are never part of a database copy and must never be
-- copied into a test project. This script removes the database rows that
-- describe ID-document files and clears uploader metadata on all others.
--
-- What changes and what is kept: docs/W6-SEED-AND-ANONYMIZER.md §3.
-- =====================================================================
do $anonymize$
declare
  c_prod_ref     constant text   := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  v_target text := nullif(btrim(coalesce(current_setting('purple.anonymize_target', true), '')), '');
  v_url    text;
  v_ref    text;
begin
  -- ---------------------------------------------------------------- guard
  if v_target is null then
    raise exception 'anonymize refused: set purple.anonymize_target to this project''s ref (or ''local'') first';
  end if;
  if position(c_prod_ref in lower(v_target)) > 0 then
    raise exception 'anonymize refused: production is never anonymized in place';
  end if;
  begin
    select decrypted_secret into strict v_url from vault.decrypted_secrets where name = 'project_url';
  exception
    when no_data_found then raise exception 'anonymize refused: Vault project_url is missing, so this database cannot be verified';
    when too_many_rows then raise exception 'anonymize refused: more than one Vault project_url';
    when others then raise exception 'anonymize refused: Vault project_url cannot be read (%)', sqlerrm;
  end;
  if v_url is null or btrim(v_url) = '' then
    raise exception 'anonymize refused: Vault project_url is empty';
  end if;
  if position(c_prod_ref in lower(v_url)) > 0 then
    raise exception 'anonymize refused: production is never anonymized in place';
  end if;
  if v_target = 'local' then
    if v_url !~ '^https?://(127\.0\.0\.1|localhost|kong|host\.docker\.internal)(:[0-9]+)?/?$' then
      raise exception 'anonymize refused: target is local but project_url (%) is not a local address', v_url;
    end if;
  else
    v_ref := substring(v_url from '^https://([a-z0-9]{20})\.supabase\.co/?$');
    if v_ref is null or v_ref <> v_target then
      raise exception 'anonymize refused: target % does not match this database (%)', v_target, v_url;
    end if;
    if not (v_ref = any (c_staging_refs)) then
      raise exception 'anonymize refused: % is not an approved staging project', v_ref;
    end if;
  end if;

  -- Audit, review and history guards block edits on purpose; pause them for this transaction only.
  alter table public.reviews disable trigger reviews_protect;
  alter table public.security_events disable trigger security_events_append_only;
  alter table public.seller_status_history disable trigger seller_status_history_append_only;

  -- 1. Sign-in data
  update auth.users u set
    email = 'user-' || left(md5(u.id::text), 12) || '@anon.purple.test',
    phone = null,
    raw_user_meta_data = jsonb_build_object('username', 'user_' || left(md5(u.id::text), 10),
                                            'display_name', 'Member ' || left(md5(u.id::text), 6)),
    encrypted_password = extensions.crypt(encode(extensions.gen_random_bytes(24), 'hex'), extensions.gen_salt('bf', 10)),
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
    status_reason = case when p.status_reason is not null then 'Anonymised reason' end,
    referral_code = left(md5('referral/' || p.id::text), 8);                                  -- F1
  update public.seller_register r set
    shop_name = case when r.anonymised_at is not null then r.shop_name
                     else coalesce('Shop ' || left(md5(r.seller_id::text), 6), 'Deleted seller #' || r.seller_no) end,
    username  = case when r.seller_id is not null and r.anonymised_at is null then 'user_' || left(md5(r.seller_id::text), 10) end,
    status_reason = case when r.status_reason is not null then 'Anonymised reason' end;
  update public.seller_status_history set reason = 'Anonymised reason' where reason is not null;
  update public.pro_entries set
    title        = initcap(kind::text) || ' entry',                                           -- F2
    organisation = case when organisation is not null then 'Organisation' end,
    location     = null,
    description  = null;

  -- 3. Identity and bank details
  update public.seller_verifications set
    id_document_path = null,
    id_document_deleted_at = coalesce(id_document_deleted_at, now()),
    account_name = 'Account holder', account_last4 = '0000',
    bank_code = null, payment_recipient_code = null,
    rejection_reason = case when rejection_reason is not null then 'Anonymised note.' end;   -- F4

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
  -- F4: notes written by the moderation team
  update public.listings set rejection_reason = 'Anonymised note.' where rejection_reason is not null;
  update public.story_videos set moderation_note = 'Anonymised note.' where moderation_note is not null;

  -- 6. Logs that can hold personal details
  update public.security_events set details = jsonb_build_object('anonymised', true) where details is not null;
  update public.risk_flags set details = jsonb_build_object('anonymised', true), review_note = null;

  -- 7. Storage rows (F3). Object names are random (see src/lib/upload.ts); ID-document rows are removed entirely.
  perform set_config('storage.allow_delete_query', 'true', true);
  delete from storage.objects where bucket_id = 'id-documents';
  update storage.objects set user_metadata = null where user_metadata is not null;

  alter table public.reviews enable trigger reviews_protect;
  alter table public.security_events enable trigger security_events_append_only;
  alter table public.seller_status_history enable trigger seller_status_history_append_only;

  raise notice 'anonymize: done for %', v_target;
end $anonymize$;
