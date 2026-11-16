CREATE OR REPLACE FUNCTION public.cancel_account_deletion()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if auth.uid() is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  update public.profiles set deletion_requested_at = null
  where id = auth.uid() and deletion_requested_at is not null and deleted_at is null;
  if found then
    perform public.log_security_event('deletion_cancelled', auth.uid(), 'profile', auth.uid()::text);
  end if;
end $function$
