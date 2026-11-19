-- Production migration 20261112181916 request_reports_escalation: production's recorded SQL, verbatim.
-- Source: supabase_migrations.schema_migrations.statements (read-only, 2026-11-19).
-- md5 of the SQL below this 4-line header (no trailing newline): 86da2f3a72bef6ff525f59d231f6f01b
-- Replaces part of former repo file 020; commented original: docs/legacy/migrations-pre-c1/20261112000020_purple_requests.sql (C1, approved 2026-11-19).
create or replace function public.escalate_report()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare
  n int;
  buyer uuid;
begin
  perform public.log_security_event('report_filed', new.reported_user_id, 'report', new.id::text,
    jsonb_build_object('reason', new.reason, 'listing_id', new.listing_id, 'video_id', new.video_id, 'request_id', new.request_id));

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

  if new.video_id is not null then
    select count(distinct r.reporter_id) into n
    from public.reports r join public.profiles p on p.id = r.reporter_id
    where r.video_id = new.video_id and r.status = 'open'
      and p.created_at < now() - interval '3 days';
    if n >= 3 then
      update public.story_videos set status = 'hidden', moderation_note = 'Hidden automatically after reports'
      where id = new.video_id and status = 'published';
      if found then
        perform public.log_security_event('story_auto_hidden', new.reported_user_id, 'story_video', new.video_id::text,
          jsonb_build_object('open_reports', n));
      end if;
      perform public.raise_flag('story_reported', 'high', new.reported_user_id, null, 'story_video', new.video_id::text,
        jsonb_build_object('reporters', n));
    end if;
  end if;

  if new.request_id is not null then
    buyer := private.request_owner(new.request_id);
    select count(distinct r.reporter_id) into n
    from public.reports r join public.profiles p on p.id = r.reporter_id
    where r.request_id = new.request_id and r.status = 'open'
      and p.created_at < now() - interval '3 days';
    if n >= 3 and buyer is not null then
      update public.buyer_requests set status = 'closed', closed_at = now(), updated_at = now()
      where id = new.request_id and status = 'open';
      if found then
        update public.request_offers set status = 'declined', updated_at = now()
        where request_id = new.request_id and status = 'sent';
        perform public.log_security_event('request_auto_closed', buyer, 'buyer_request', new.request_id::text,
          jsonb_build_object('open_reports', n));
      end if;
      perform public.raise_flag('request_reported', 'high', buyer, null, 'buyer_request', new.request_id::text,
        jsonb_build_object('reporters', n));
    end if;
  end if;

  if new.reported_user_id is not null then
    select count(distinct reporter_id) into n from public.reports
    where reported_user_id = new.reported_user_id and created_at > now() - interval '30 days';
    if n >= 3 then
      perform public.raise_flag('reported_user', 'high', new.reported_user_id, null, null, null,
        jsonb_build_object('reporters_30d', n));
    end if;
  end if;
  return null;
end $function$;
