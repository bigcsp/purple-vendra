-- Production migration 20261112181859 request_reports_keep_buyer_hidden: production's recorded SQL, verbatim.
-- Source: supabase_migrations.schema_migrations.statements (read-only, 2026-11-19).
-- md5 of the SQL below this 4-line header (no trailing newline): 4d6e3b714f1fe678cd5ef284e151122f
-- Replaces part of former repo file 020; commented original: docs/legacy/migrations-pre-c1/20261112000020_purple_requests.sql (C1, approved 2026-11-19).
alter table public.reports drop constraint if exists reports_check;
alter table public.reports drop constraint if exists reports_has_target;
alter table public.reports add constraint reports_has_target
  check (listing_id is not null or reported_user_id is not null or video_id is not null or request_id is not null);

create or replace function public.protect_report()
returns trigger
language plpgsql
set search_path = ''
as $$
declare request_buyer uuid;
begin
  if new.listing_id is not null then
    new.reported_user_id := public.listing_seller(new.listing_id);
    if new.reported_user_id is null then
      raise exception 'That listing no longer exists' using errcode = 'P0002';
    end if;
  elsif new.video_id is not null then
    new.reported_user_id := public.story_owner(new.video_id);
    if new.reported_user_id is null then
      raise exception 'That story no longer exists' using errcode = 'P0002';
    end if;
  elsif new.request_id is not null then
    -- The buyer stays anonymous: the report stores the request only
    -- (reporters can read their own reports). Admins look up the buyer.
    request_buyer := private.request_owner(new.request_id);
    if request_buyer is null then
      raise exception 'That request no longer exists' using errcode = 'P0002';
    end if;
    new.reported_user_id := null;
  end if;

  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.reporter_id is distinct from auth.uid() then
      raise exception 'You can only send reports as yourself' using errcode = '42501';
    end if;
    if coalesce(new.reported_user_id, request_buyer) = auth.uid() then
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
