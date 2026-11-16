CREATE OR REPLACE FUNCTION public.process_account_deletion(uid uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  has_money_history boolean;
  f record;
begin
  for f in select o.bucket_id, o.name from storage.objects o
           where o.bucket_id in ('id-documents', 'listing-images', 'story-media')
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
end $function$
