CREATE OR REPLACE FUNCTION public.queue_file_deletion(p_bucket text, p_name text, p_reason text)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  insert into public.storage_deletion_queue (bucket_id, object_name, reason)
  values (p_bucket, p_name, p_reason)
  on conflict (bucket_id, object_name) do nothing;
$function$
