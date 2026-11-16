CREATE OR REPLACE FUNCTION public.run_privacy_retention()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end $function$
