CREATE OR REPLACE FUNCTION public.request_account_deletion(confirm_username text)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end $function$
