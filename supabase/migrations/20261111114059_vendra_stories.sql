-- =====================================================================
-- 012 · Vendra Stories (seller videos) + follows/cart access + campaigns
-- ---------------------------------------------------------------------
-- * story-media bucket (public, 50 MB, mp4/webm/mov + thumbnails)
-- * story_videos, story_video_products, story_likes, story_comments
-- * story_events (anonymous analytics) + story_cart_attributions (sales)
-- * story_campaigns (Promote Video; admin-activated until payments exist)
-- * follows + cart_items: first real access policies
-- * reports can target a video; 3 established reporters hide it
-- * export / account deletion / storage cleanup know about stories
-- Same safety pattern as 006–011: 2FA (can_post) for sellers, blocked
-- accounts can't write, counters and moderation fields are protected.
-- =====================================================================

-- ---------- Types ------------------------------------------------------
create type public.story_status as enum ('draft', 'published', 'hidden', 'removed');
create type public.story_event_type as enum
  ('impression', 'view', 'share', 'product_click', 'shop_visit', 'add_to_cart');
create type public.campaign_status as enum
  ('awaiting_payment', 'active', 'paused', 'completed', 'cancelled', 'rejected');

-- ---------- Storage bucket --------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('story-media', 'story-media', true, 52428800,
        array['video/mp4', 'video/webm', 'video/quicktime', 'image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public, file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "Sellers upload story media to their own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'story-media'
              and (storage.foldername(name))[1] = (select auth.uid())::text
              and (select public.can_post()));
create policy "Sellers see their own story media files" on storage.objects
  for select to authenticated
  using (bucket_id = 'story-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Sellers replace their own story media" on storage.objects
  for update to authenticated
  using (bucket_id = 'story-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text
         and (select public.can_post()));
create policy "Sellers delete their own story media" on storage.objects
  for delete to authenticated
  using (bucket_id = 'story-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text
         and (select public.can_post()));

-- ---------- Tables -----------------------------------------------------
create table public.story_videos (
  id               uuid primary key default gen_random_uuid(),
  seller_id        uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title            text not null check (char_length(btrim(title)) between 3 and 120),
  description      text not null default '' check (char_length(description) <= 2000),
  category_id      smallint not null references public.categories(id),
  video_path       text not null,
  thumbnail_path   text,
  duration_seconds numeric(6,1) check (duration_seconds is null or duration_seconds between 1 and 180),
  size_bytes       bigint check (size_bytes is null or size_bytes between 1 and 52428800),
  width            int,
  height           int,
  status           public.story_status not null default 'draft',
  moderation_note  text,
  view_count       int not null default 0,
  like_count       int not null default 0,
  comment_count    int not null default 0,
  share_count      int not null default 0,
  published_at     timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index story_videos_seller on public.story_videos (seller_id, created_at desc);
create index story_videos_public on public.story_videos (published_at desc) where status = 'published';
create index story_videos_category on public.story_videos (category_id) where status = 'published';

create table public.story_video_products (
  video_id   uuid not null references public.story_videos(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  position   smallint not null default 0,
  primary key (video_id, listing_id)
);
create index story_video_products_listing on public.story_video_products (listing_id);

create table public.story_likes (
  video_id   uuid not null references public.story_videos(id) on delete cascade,
  user_id    uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (video_id, user_id)
);
create index story_likes_user on public.story_likes (user_id);

create table public.story_comments (
  id         uuid primary key default gen_random_uuid(),
  video_id   uuid not null references public.story_videos(id) on delete cascade,
  user_id    uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  body       text not null check (char_length(btrim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index story_comments_video on public.story_comments (video_id, created_at desc);
create index story_comments_user on public.story_comments (user_id, created_at desc);

-- Analytics events never store who did them (same rule as listing_events).
create table public.story_events (
  id          bigint generated always as identity primary key,
  video_id    uuid not null references public.story_videos(id) on delete cascade,
  event_type  public.story_event_type not null,
  listing_id  uuid references public.listings(id) on delete set null,
  campaign_id uuid,
  created_at  timestamptz not null default now()
);
create index story_events_video on public.story_events (video_id, created_at);
create index story_events_campaign on public.story_events (campaign_id, created_at) where campaign_id is not null;

create table public.story_campaigns (
  id                uuid primary key default gen_random_uuid(),
  seller_id         uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  video_id          uuid not null references public.story_videos(id) on delete cascade,
  audience_categories smallint[] not null default '{}',
  audience_states   text[] not null default '{}',
  audience_note     text check (char_length(audience_note) <= 300),
  duration_days     smallint not null check (duration_days between 1 and 30),
  budget_kobo       bigint not null check (budget_kobo between 100000 and 100000000),
  status            public.campaign_status not null default 'awaiting_payment',
  payment_reference text,
  admin_note        text,
  starts_at         timestamptz,
  ends_at           timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index story_campaigns_seller on public.story_campaigns (seller_id, created_at desc);
create index story_campaigns_live on public.story_campaigns (ends_at) where status = 'active';
alter table public.story_events
  add constraint story_events_campaign_fk foreign key (campaign_id) references public.story_campaigns(id) on delete set null;

-- Which video sent a product to someone's cart (for "sales from video").
create table public.story_cart_attributions (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  listing_id  uuid not null references public.listings(id) on delete cascade,
  video_id    uuid not null references public.story_videos(id) on delete cascade,
  campaign_id uuid references public.story_campaigns(id) on delete set null,
  created_at  timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index story_cart_attr_video on public.story_cart_attributions (video_id);

alter table public.story_videos            enable row level security;
alter table public.story_video_products    enable row level security;
alter table public.story_likes             enable row level security;
alter table public.story_comments          enable row level security;
alter table public.story_events            enable row level security;
alter table public.story_campaigns         enable row level security;
alter table public.story_cart_attributions enable row level security;

create trigger story_videos_updated_at before update on public.story_videos
  for each row execute function public.set_updated_at();
create trigger story_campaigns_updated_at before update on public.story_campaigns
  for each row execute function public.set_updated_at();

-- ---------- Helpers ----------------------------------------------------
-- A video anyone may watch: published and its seller isn't blocked.
create or replace function public.story_is_public(p_video uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.story_videos v
                 where v.id = p_video and v.status = 'published' and public.account_ok(v.seller_id));
$$;

create or replace function public.story_owner(p_video uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select seller_id from public.story_videos where id = p_video;
$$;

-- ---------- story_videos policies -------------------------------------
create policy "Published stories are public" on public.story_videos
  for select to anon, authenticated using (status = 'published' and public.account_ok(seller_id));
create policy "Sellers see their own stories" on public.story_videos
  for select to authenticated using (seller_id = (select auth.uid()));
create policy "Sellers create their own stories" on public.story_videos
  for insert to authenticated with check (seller_id = (select auth.uid()));
create policy "Sellers edit their own stories" on public.story_videos
  for update to authenticated using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()));
create policy "Sellers delete their own stories" on public.story_videos
  for delete to authenticated using (seller_id = (select auth.uid()));
create policy "Admins manage all stories" on public.story_videos
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

-- ---------- story_video_products policies -----------------------------
create policy "Products on public stories are public" on public.story_video_products
  for select to anon, authenticated using (public.story_is_public(video_id));
create policy "Sellers see products on their own stories" on public.story_video_products
  for select to authenticated using (public.story_owner(video_id) = (select auth.uid()));
create policy "Sellers tag their own listings on their own stories" on public.story_video_products
  for insert to authenticated
  with check (public.story_owner(video_id) = (select auth.uid())
              and public.listing_seller(listing_id) = (select auth.uid()));
create policy "Sellers reorder products on their own stories" on public.story_video_products
  for update to authenticated
  using (public.story_owner(video_id) = (select auth.uid()))
  with check (public.story_owner(video_id) = (select auth.uid())
              and public.listing_seller(listing_id) = (select auth.uid()));
create policy "Sellers untag products on their own stories" on public.story_video_products
  for delete to authenticated using (public.story_owner(video_id) = (select auth.uid()));
create policy "Admins manage story products" on public.story_video_products
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

-- ---------- story_likes policies --------------------------------------
create policy "People see their own likes" on public.story_likes
  for select to authenticated using (user_id = (select auth.uid()));
create policy "People like public stories" on public.story_likes
  for insert to authenticated
  with check (user_id = (select auth.uid()) and public.story_is_public(video_id));
create policy "People unlike" on public.story_likes
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---------- story_comments policies -----------------------------------
-- Reading comments goes through get_story_comments() (shows names of
-- buyers, whose profiles aren't public). Direct reads: own + seller + admin.
create policy "People see their own comments" on public.story_comments
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Sellers see comments on their stories" on public.story_comments
  for select to authenticated using (public.story_owner(video_id) = (select auth.uid()));
create policy "Admins see all comments" on public.story_comments
  for select to authenticated using ((select public.is_admin()));
create policy "People comment on public stories" on public.story_comments
  for insert to authenticated
  with check (user_id = (select auth.uid()) and public.story_is_public(video_id));
create policy "Authors, the story's seller or admins delete comments" on public.story_comments
  for delete to authenticated
  using (user_id = (select auth.uid())
         or public.story_owner(video_id) = (select auth.uid())
         or (select public.is_admin()));

-- ---------- story_events / attributions: no direct access --------------
-- Written only by record_story_event() / add_story_product_to_cart();
-- read only through get_story_analytics(). (RLS on, no policies.)

-- ---------- story_campaigns policies ----------------------------------
create policy "Sellers see their own campaigns" on public.story_campaigns
  for select to authenticated using (seller_id = (select auth.uid()));
create policy "Sellers create campaigns for their own stories" on public.story_campaigns
  for insert to authenticated
  with check (seller_id = (select auth.uid()) and public.story_owner(video_id) = (select auth.uid()));
create policy "Sellers update their own campaigns" on public.story_campaigns
  for update to authenticated using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()));
create policy "Admins manage all campaigns" on public.story_campaigns
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

-- ---------- Seller 2FA + blocked-account rules (same as 006/009) -------
do $$
declare t text;
begin
  foreach t in array array['story_videos', 'story_video_products', 'story_campaigns'] loop
    execute format('create policy "Sellers must use 2FA to insert" on public.%I as restrictive for insert to anon, authenticated with check ((select public.can_post()))', t);
    execute format('create policy "Sellers must use 2FA to update" on public.%I as restrictive for update to anon, authenticated using ((select public.can_post()))', t);
  end loop;
  -- Deleting a story needs 2FA too; untagging products as well.
  execute 'create policy "Sellers must use 2FA to delete" on public.story_videos as restrictive for delete to anon, authenticated using ((select public.can_post()) or (select public.is_admin()))';
  execute 'create policy "Sellers must use 2FA to delete" on public.story_video_products as restrictive for delete to anon, authenticated using ((select public.can_post()))';

  foreach t in array array['story_videos', 'story_video_products', 'story_likes', 'story_comments', 'story_campaigns'] loop
    execute format('create policy "Blocked accounts cannot insert" on public.%I as restrictive for insert to authenticated with check ((select public.account_ok(auth.uid())))', t);
    execute format('create policy "Blocked accounts cannot update" on public.%I as restrictive for update to authenticated using ((select public.account_ok(auth.uid())))', t);
    execute format('create policy "Blocked accounts cannot delete" on public.%I as restrictive for delete to authenticated using ((select public.account_ok(auth.uid())))', t);
  end loop;
end $$;

-- ---------- Protect story fields --------------------------------------
create or replace function public.protect_story_video()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.seller_id is distinct from auth.uid() then
        raise exception 'You can only post stories as yourself' using errcode = '42501';
      end if;
      if new.status not in ('draft', 'published') then
        raise exception 'Stories start as a draft or published' using errcode = '42501';
      end if;
      if (select count(*) from public.story_videos
          where seller_id = new.seller_id and created_at > now() - interval '24 hours') >= 10 then
        raise exception 'You can post 10 stories a day. Please try again tomorrow.' using errcode = '54000';
      end if;
      new.view_count := 0; new.like_count := 0; new.comment_count := 0; new.share_count := 0;
      new.moderation_note := null;
    else
      if new.seller_id is distinct from old.seller_id
      or new.view_count is distinct from old.view_count
      or new.like_count is distinct from old.like_count
      or new.comment_count is distinct from old.comment_count
      or new.share_count is distinct from old.share_count
      or new.moderation_note is distinct from old.moderation_note then
        raise exception 'You can''t change that part of a story' using errcode = '42501';
      end if;
      if old.status in ('hidden', 'removed') and new.status is distinct from old.status then
        raise exception 'This story is under review by the Purple Vendra team' using errcode = '42501';
      end if;
      if new.status in ('hidden', 'removed') and new.status is distinct from old.status then
        raise exception 'Only the Purple Vendra team can hide stories' using errcode = '42501';
      end if;
    end if;
    -- Files must live in the seller's own folder of the story-media bucket.
    if new.video_path not like new.seller_id::text || '/%'
       or (new.thumbnail_path is not null and new.thumbnail_path not like new.seller_id::text || '/%') then
      raise exception 'Upload the video to your own folder first' using errcode = '42501';
    end if;
  end if;

  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  -- Swapped files: queue the old ones for the nightly cleanup.
  if tg_op = 'UPDATE' then
    if new.video_path is distinct from old.video_path then
      perform public.queue_file_deletion('story-media', old.video_path, 'story_replaced');
    end if;
    if old.thumbnail_path is not null and new.thumbnail_path is distinct from old.thumbnail_path then
      perform public.queue_file_deletion('story-media', old.thumbnail_path, 'story_replaced');
    end if;
  end if;
  return new;
end $$;
create trigger story_videos_protect before insert or update on public.story_videos
  for each row execute function public.protect_story_video();

-- Off-platform contact in a story's text → risk flag (same regex as 010).
create or replace function public.check_story_risk()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if public.looks_like_off_platform(new.title || ' ' || coalesce(new.description, '')) then
    perform public.raise_flag('off_platform_contact', 'medium', new.seller_id, null, 'story_video', new.id::text,
      jsonb_build_object('title', left(new.title, 120)));
  end if;
  return null;
end $$;
create trigger story_videos_risk_check after insert or update of title, description on public.story_videos
  for each row execute function public.check_story_risk();

-- Deleted story → its files go to the nightly storage cleanup.
create or replace function public.queue_story_files()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.queue_file_deletion('story-media', old.video_path, 'story_deleted');
  if old.thumbnail_path is not null then
    perform public.queue_file_deletion('story-media', old.thumbnail_path, 'story_deleted');
  end if;
  return null;
end $$;
create trigger story_videos_queue_files after delete on public.story_videos
  for each row execute function public.queue_story_files();

-- Max 6 products per story.
create or replace function public.limit_story_products()
returns trigger language plpgsql set search_path = '' as $$
begin
  if (select count(*) from public.story_video_products where video_id = new.video_id) >= 6 then
    raise exception 'You can tag up to 6 products on a story' using errcode = '54000';
  end if;
  return new;
end $$;
create trigger story_video_products_limit before insert on public.story_video_products
  for each row execute function public.limit_story_products();

-- Like / comment counters (kept by the database, not the browser).
create or replace function public.sync_story_counters()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name = 'story_likes' then
    update public.story_videos set like_count = greatest(0, like_count + case when tg_op = 'INSERT' then 1 else -1 end)
    where id = coalesce(new.video_id, old.video_id);
  else
    update public.story_videos set comment_count = greatest(0, comment_count + case when tg_op = 'INSERT' then 1 else -1 end)
    where id = coalesce(new.video_id, old.video_id);
  end if;
  return null;
end $$;
create trigger story_likes_count after insert or delete on public.story_likes
  for each row execute function public.sync_story_counters();
create trigger story_comments_count after insert or delete on public.story_comments
  for each row execute function public.sync_story_counters();

-- Comments: 30 an hour, author fixed, off-platform contact flagged.
create or replace function public.protect_story_comment()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') then
    if new.user_id is distinct from auth.uid() then
      raise exception 'You can only comment as yourself' using errcode = '42501';
    end if;
    if (select count(*) from public.story_comments
        where user_id = auth.uid() and created_at > now() - interval '1 hour') >= 30 then
      raise exception 'You''re commenting very fast. Please wait a little.' using errcode = '54000';
    end if;
  end if;
  new.body := btrim(new.body);
  return new;
end $$;
create trigger story_comments_protect before insert on public.story_comments
  for each row execute function public.protect_story_comment();

create or replace function public.check_story_comment_risk()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if public.looks_like_off_platform(new.body) then
    perform public.raise_flag('off_platform_contact', 'low', new.user_id, null, 'story_comment', new.id::text,
      jsonb_build_object('video_id', new.video_id, 'body', left(new.body, 200)));
  end if;
  return null;
end $$;
create trigger story_comments_risk_check after insert on public.story_comments
  for each row execute function public.check_story_comment_risk();

-- ---------- Campaign rules --------------------------------------------
create or replace function public.protect_story_campaign()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.seller_id is distinct from auth.uid() then
        raise exception 'You can only create campaigns as yourself' using errcode = '42501';
      end if;
      if not exists (select 1 from public.story_videos
                     where id = new.video_id and seller_id = auth.uid() and status = 'published') then
        raise exception 'Publish the story before promoting it' using errcode = '42501';
      end if;
      if (select count(*) from public.story_campaigns
          where seller_id = auth.uid() and status in ('awaiting_payment', 'active', 'paused')) >= 5 then
        raise exception 'You can have 5 open campaigns at a time' using errcode = '54000';
      end if;
      new.status := 'awaiting_payment';
      new.payment_reference := null; new.admin_note := null;
      new.starts_at := null; new.ends_at := null;
    else
      if new.video_id is distinct from old.video_id
      or new.budget_kobo is distinct from old.budget_kobo
      or new.duration_days is distinct from old.duration_days
      or new.payment_reference is distinct from old.payment_reference
      or new.admin_note is distinct from old.admin_note
      or new.starts_at is distinct from old.starts_at
      or new.ends_at is distinct from old.ends_at then
        raise exception 'You can''t change that part of a campaign' using errcode = '42501';
      end if;
      if new.status is distinct from old.status and not (
           (old.status = 'awaiting_payment' and new.status = 'cancelled')
        or (old.status = 'active' and new.status = 'paused')
        or (old.status = 'paused' and new.status = 'active' and old.ends_at > now())) then
        raise exception 'That campaign change isn''t allowed' using errcode = '42501';
      end if;
      if old.status <> 'awaiting_payment' and (
           new.audience_categories is distinct from old.audience_categories
        or new.audience_states is distinct from old.audience_states) then
        raise exception 'The audience is fixed once a campaign is paid' using errcode = '42501';
      end if;
    end if;
  end if;
  return new;
end $$;
create trigger story_campaigns_protect before insert or update on public.story_campaigns
  for each row execute function public.protect_story_campaign();

-- Admin: payment received → campaign goes live for its full duration.
create or replace function public.admin_activate_campaign(p_campaign uuid, p_payment_reference text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only (with 2FA)' using errcode = '42501'; end if;
  if coalesce(btrim(p_payment_reference), '') = '' then
    raise exception 'Enter the payment reference' using errcode = '22023';
  end if;
  update public.story_campaigns
  set status = 'active', payment_reference = btrim(p_payment_reference),
      starts_at = now(), ends_at = now() + make_interval(days => duration_days)
  where id = p_campaign and status = 'awaiting_payment';
  if not found then raise exception 'Campaign not found or not awaiting payment' using errcode = 'P0002'; end if;
  perform public.log_security_event('campaign_activated', (select seller_id from public.story_campaigns where id = p_campaign),
    'story_campaign', p_campaign::text, jsonb_build_object('payment_reference', p_payment_reference));
end $$;

create or replace function public.admin_reject_campaign(p_campaign uuid, p_note text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only (with 2FA)' using errcode = '42501'; end if;
  update public.story_campaigns set status = 'rejected', admin_note = left(p_note, 500)
  where id = p_campaign and status in ('awaiting_payment', 'active', 'paused');
  if not found then raise exception 'Campaign not found' using errcode = 'P0002'; end if;
  perform public.log_security_event('campaign_rejected', (select seller_id from public.story_campaigns where id = p_campaign),
    'story_campaign', p_campaign::text, jsonb_build_object('note', p_note));
end $$;

create or replace function public.admin_moderate_story(p_video uuid, p_status public.story_status, p_note text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Admins only (with 2FA)' using errcode = '42501'; end if;
  update public.story_videos set status = p_status, moderation_note = left(p_note, 500) where id = p_video;
  if not found then raise exception 'Story not found' using errcode = 'P0002'; end if;
  perform public.log_security_event('story_moderated', (select seller_id from public.story_videos where id = p_video),
    'story_video', p_video::text, jsonb_build_object('status', p_status, 'note', p_note));
end $$;

-- Finished campaigns close themselves (hourly).
create or replace function public.complete_finished_campaigns()
returns int language sql security definer set search_path = '' as $$
  with done as (
    update public.story_campaigns set status = 'completed'
    where status in ('active', 'paused') and ends_at <= now() returning 1)
  select count(*)::int from done;
$$;
select cron.schedule('story-campaigns-complete', '7 * * * *', 'select public.complete_finished_campaigns()');

-- ---------- Public read functions -------------------------------------
-- Comments with the commenter's display name (buyer profiles aren't public).
create or replace function public.get_story_comments(p_video uuid, p_limit int default 50)
returns table (id uuid, body text, created_at timestamptz, user_id uuid,
               display_name text, username text, is_seller boolean)
language sql stable security definer set search_path = '' as $$
  select c.id, c.body, c.created_at, c.user_id, p.display_name, p.username, (c.user_id = v.seller_id)
  from public.story_comments c
  join public.story_videos v on v.id = c.video_id
  join public.profiles p on p.id = c.user_id
  where c.video_id = p_video
    and (public.story_is_public(p_video) or v.seller_id = auth.uid() or public.is_admin())
    and public.account_ok(c.user_id)
  order by c.created_at desc
  limit least(greatest(p_limit, 1), 200);
$$;

-- Follower count + whether the viewer follows.
create or replace function public.seller_follow_info(p_seller uuid)
returns table (followers bigint, following boolean)
language sql stable security definer set search_path = '' as $$
  select (select count(*) from public.follows f where f.seller_id = p_seller),
         exists (select 1 from public.follows f where f.seller_id = p_seller and f.follower_id = auth.uid());
$$;

-- Discovery feed: live promoted stories (matching the audience) first,
-- then the newest stories. Returns campaign_id so impressions are counted.
create or replace function public.get_story_feed(p_category smallint default null, p_limit int default 24)
returns table (video_id uuid, title text, video_path text, thumbnail_path text, category_id smallint,
               view_count int, like_count int, seller_id uuid, seller_username text,
               seller_name text, seller_verified boolean, campaign_id uuid, published_at timestamptz)
language sql stable security definer set search_path = '' as $$
  with viewer as (select p.state from public.profiles p where p.id = auth.uid()),
  promoted as (
    select distinct on (c.video_id) c.video_id, c.id as campaign_id
    from public.story_campaigns c
    where c.status = 'active' and c.ends_at > now()
      and (cardinality(c.audience_categories) = 0 or p_category is null or p_category = any (c.audience_categories))
      and (cardinality(c.audience_states) = 0
           or exists (select 1 from viewer where viewer.state = any (c.audience_states)))
    order by c.video_id, c.budget_kobo desc
  )
  select v.id, v.title, v.video_path, v.thumbnail_path, v.category_id, v.view_count, v.like_count,
         v.seller_id, p.username, coalesce(p.business_name, p.display_name), p.is_verified,
         pr.campaign_id, v.published_at
  from public.story_videos v
  join public.profiles p on p.id = v.seller_id
  left join promoted pr on pr.video_id = v.id
  where v.status = 'published' and public.account_ok(v.seller_id)
    and (p_category is null or v.category_id = p_category or pr.campaign_id is not null)
  order by (pr.campaign_id is not null) desc, v.published_at desc
  limit least(greatest(p_limit, 1), 60);
$$;

-- ---------- Event recording (anonymous) -------------------------------
create or replace function public.record_story_event(
  p_video uuid, p_type public.story_event_type, p_listing uuid default null, p_campaign uuid default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.story_is_public(p_video) then return; end if;
  -- Sellers watching their own stories don't count.
  if auth.uid() is not null and auth.uid() = public.story_owner(p_video) then return; end if;
  if p_type = 'add_to_cart' then
    raise exception 'Use add_story_product_to_cart' using errcode = '22023';
  end if;
  if p_listing is not null and not exists (
       select 1 from public.story_video_products where video_id = p_video and listing_id = p_listing) then
    p_listing := null;
  end if;
  if p_campaign is not null and not exists (
       select 1 from public.story_campaigns c
       where c.id = p_campaign and c.video_id = p_video and c.status = 'active' and c.ends_at > now()) then
    p_campaign := null;
  end if;

  insert into public.story_events (video_id, event_type, listing_id, campaign_id)
  values (p_video, p_type, p_listing, p_campaign);

  if p_type = 'view' then
    update public.story_videos set view_count = view_count + 1 where id = p_video;
  elsif p_type = 'share' then
    update public.story_videos set share_count = share_count + 1 where id = p_video;
  end if;
end $$;

-- Add a product featured in a story to the cart (and remember the story).
create or replace function public.add_story_product_to_cart(
  p_video uuid, p_listing uuid, p_campaign uuid default null)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Please sign in to add to your cart' using errcode = '42501'; end if;
  if not public.account_ok(uid) then raise exception 'Your account can''t do this right now' using errcode = '42501'; end if;
  if not public.story_is_public(p_video) then raise exception 'This story isn''t available' using errcode = 'P0002'; end if;
  if not exists (select 1 from public.story_video_products sp
                 join public.listings l on l.id = sp.listing_id
                 where sp.video_id = p_video and sp.listing_id = p_listing
                   and l.status = 'approved' and public.account_ok(l.seller_id)) then
    raise exception 'This product isn''t available' using errcode = 'P0002';
  end if;
  if public.listing_seller(p_listing) = uid then
    raise exception 'You can''t buy your own listing' using errcode = '42501';
  end if;
  if p_campaign is not null and not exists (
       select 1 from public.story_campaigns c
       where c.id = p_campaign and c.video_id = p_video and c.status = 'active' and c.ends_at > now()) then
    p_campaign := null;
  end if;

  insert into public.cart_items (user_id, listing_id, quantity) values (uid, p_listing, 1)
  on conflict (user_id, listing_id) do nothing;

  insert into public.story_cart_attributions (user_id, listing_id, video_id, campaign_id)
  values (uid, p_listing, p_video, p_campaign)
  on conflict (user_id, listing_id) do update
    set video_id = excluded.video_id, campaign_id = excluded.campaign_id, created_at = now();

  insert into public.story_events (video_id, event_type, listing_id, campaign_id)
  values (p_video, 'add_to_cart', p_listing, p_campaign);
end $$;

-- ---------- Seller analytics ------------------------------------------
-- Per-story totals for the signed-in seller over the last p_days.
-- Sales = paid orders (not cancelled/refunded) of a tagged product by a
-- buyer who added it to their cart from the story, within 7 days.
create or replace function public.get_story_analytics(p_days int default 30)
returns table (video_id uuid, title text, status public.story_status, thumbnail_path text,
               impressions bigint, views bigint, likes bigint, comments bigint, shares bigint,
               product_clicks bigint, shop_visits bigint, add_to_carts bigint,
               orders bigint, sales_kobo bigint)
language sql stable security definer set search_path = '' as $$
  with mine as (select v.* from public.story_videos v where v.seller_id = auth.uid()),
  since as (select now() - make_interval(days => least(greatest(p_days, 1), 365)) as t),
  ev as (
    select e.video_id,
           count(*) filter (where e.event_type = 'impression')    as impressions,
           count(*) filter (where e.event_type = 'view')          as views,
           count(*) filter (where e.event_type = 'share')         as shares,
           count(*) filter (where e.event_type = 'product_click') as product_clicks,
           count(*) filter (where e.event_type = 'shop_visit')    as shop_visits,
           count(*) filter (where e.event_type = 'add_to_cart')   as add_to_carts
    from public.story_events e join mine m on m.id = e.video_id, since
    where e.created_at >= since.t group by e.video_id),
  lk as (select l.video_id, count(*) n from public.story_likes l join mine m on m.id = l.video_id, since
         where l.created_at >= since.t group by l.video_id),
  cm as (select c.video_id, count(*) n from public.story_comments c join mine m on m.id = c.video_id, since
         where c.created_at >= since.t group by c.video_id),
  sales as (
    select a.video_id, count(distinct o.id) as orders,
           coalesce(sum(oi.unit_price_kobo * oi.quantity), 0)::bigint as sales_kobo
    from public.story_cart_attributions a
    join mine m on m.id = a.video_id
    join public.orders o on o.buyer_id = a.user_id and o.seller_id = auth.uid()
         and o.created_at between a.created_at and a.created_at + interval '7 days'
         and o.status not in ('cancelled', 'refunded')
    join public.order_items oi on oi.order_id = o.id and oi.listing_id = a.listing_id, since
    where o.created_at >= since.t
    group by a.video_id)
  select m.id, m.title, m.status, m.thumbnail_path,
         coalesce(ev.impressions, 0), coalesce(ev.views, 0), coalesce(lk.n, 0), coalesce(cm.n, 0),
         coalesce(ev.shares, 0), coalesce(ev.product_clicks, 0), coalesce(ev.shop_visits, 0),
         coalesce(ev.add_to_carts, 0), coalesce(sales.orders, 0), coalesce(sales.sales_kobo, 0)
  from mine m
  left join ev on ev.video_id = m.id
  left join lk on lk.video_id = m.id
  left join cm on cm.video_id = m.id
  left join sales on sales.video_id = m.id
  order by m.created_at desc;
$$;

-- Per-campaign results for the signed-in seller.
create or replace function public.get_campaign_analytics()
returns table (campaign_id uuid, video_id uuid, video_title text, status public.campaign_status,
               budget_kobo bigint, duration_days smallint, starts_at timestamptz, ends_at timestamptz,
               impressions bigint, views bigint, product_clicks bigint, shop_visits bigint,
               add_to_carts bigint, orders bigint, sales_kobo bigint)
language sql stable security definer set search_path = '' as $$
  with mine as (select c.* from public.story_campaigns c where c.seller_id = auth.uid()),
  ev as (
    select e.campaign_id,
           count(*) filter (where e.event_type = 'impression')    as impressions,
           count(*) filter (where e.event_type = 'view')          as views,
           count(*) filter (where e.event_type = 'product_click') as product_clicks,
           count(*) filter (where e.event_type = 'shop_visit')    as shop_visits,
           count(*) filter (where e.event_type = 'add_to_cart')   as add_to_carts
    from public.story_events e join mine m on m.id = e.campaign_id group by e.campaign_id),
  sales as (
    select a.campaign_id, count(distinct o.id) orders,
           coalesce(sum(oi.unit_price_kobo * oi.quantity), 0)::bigint sales_kobo
    from public.story_cart_attributions a
    join mine m on m.id = a.campaign_id
    join public.orders o on o.buyer_id = a.user_id and o.seller_id = auth.uid()
         and o.created_at between a.created_at and a.created_at + interval '7 days'
         and o.status not in ('cancelled', 'refunded')
    join public.order_items oi on oi.order_id = o.id and oi.listing_id = a.listing_id
    group by a.campaign_id)
  select m.id, m.video_id, v.title, m.status, m.budget_kobo, m.duration_days, m.starts_at, m.ends_at,
         coalesce(ev.impressions, 0), coalesce(ev.views, 0), coalesce(ev.product_clicks, 0),
         coalesce(ev.shop_visits, 0), coalesce(ev.add_to_carts, 0),
         coalesce(sales.orders, 0), coalesce(sales.sales_kobo, 0)
  from mine m join public.story_videos v on v.id = m.video_id
  left join ev on ev.campaign_id = m.id
  left join sales on sales.campaign_id = m.id
  order by m.created_at desc;
$$;

-- ---------- Follows + cart: first real access ------------------------
create policy "People see who they follow" on public.follows
  for select to authenticated using (follower_id = (select auth.uid()));
create policy "People follow active sellers" on public.follows
  for insert to authenticated
  with check (follower_id = (select auth.uid())
              and exists (select 1 from public.profiles p
                          where p.id = seller_id and p.role = 'seller' and public.account_ok(p.id)));
create policy "People unfollow" on public.follows
  for delete to authenticated using (follower_id = (select auth.uid()));

create policy "People see their own cart" on public.cart_items
  for select to authenticated using (user_id = (select auth.uid()));
create policy "People add approved listings to their cart" on public.cart_items
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.listings l
                          where l.id = listing_id and l.status = 'approved'
                            and l.seller_id <> (select auth.uid()) and public.account_ok(l.seller_id)));
create policy "People change quantities in their cart" on public.cart_items
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "People remove items from their cart" on public.cart_items
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---------- Reports can target a story --------------------------------
alter table public.reports add column video_id uuid references public.story_videos(id) on delete cascade;
create index reports_video on public.reports (video_id) where video_id is not null;
drop index public.reports_one_open_per_target;
create unique index reports_one_open_per_target on public.reports
  (reporter_id, listing_id, reported_user_id, video_id) nulls not distinct where status = 'open';

create or replace function public.protect_report()
returns trigger language plpgsql set search_path = '' as $$
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
  end if;

  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.reporter_id is distinct from auth.uid() then
      raise exception 'You can only send reports as yourself' using errcode = '42501';
    end if;
    if new.reported_user_id = auth.uid() then
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

create or replace function public.escalate_report()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  perform public.log_security_event('report_filed', new.reported_user_id, 'report', new.id::text,
    jsonb_build_object('reason', new.reason, 'listing_id', new.listing_id, 'video_id', new.video_id));

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

  select count(distinct reporter_id) into n from public.reports
  where reported_user_id = new.reported_user_id and created_at > now() - interval '30 days';
  if n >= 3 then
    perform public.raise_flag('reported_user', 'high', new.reported_user_id, null, null, null,
      jsonb_build_object('reporters_30d', n));
  end if;
  return null;
end $$;

-- ---------- Privacy: deletion + export know about stories -------------
-- Anonymised (deleted) accounts lose their stories, likes and comments.
create or replace function public.purge_stories_on_account_deletion()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from public.story_comments where user_id = new.id;
    delete from public.story_likes where user_id = new.id;
    delete from public.story_cart_attributions where user_id = new.id;
    update public.story_campaigns set status = 'cancelled', audience_note = null
      where seller_id = new.id and status in ('awaiting_payment', 'active', 'paused');
    delete from public.story_videos where seller_id = new.id
      and not exists (select 1 from public.story_campaigns c where c.video_id = story_videos.id and c.payment_reference is not null);
    update public.story_videos set status = 'removed', title = 'Removed story', description = ''
      where seller_id = new.id;
  end if;
  return null;
end $$;
create trigger profiles_purge_stories after update of deleted_at on public.profiles
  for each row execute function public.purge_stories_on_account_deletion();

do $$
declare def text;
begin
  -- process_account_deletion also queues story-media files.
  def := pg_get_functiondef('public.process_account_deletion(uuid)'::regprocedure);
  def := replace(def, $q$o.bucket_id in ('id-documents', 'listing-images')$q$,
                      $q$o.bucket_id in ('id-documents', 'listing-images', 'story-media')$q$);
  execute def;

  -- export_my_data includes stories, likes, comments and campaigns.
  def := pg_get_functiondef('public.export_my_data()'::regprocedure);
  def := replace(def, $q$'security_events_about_you',$q$,
    $q$'stories', coalesce((select jsonb_agg(to_jsonb(v)) from public.story_videos v where v.seller_id = uid), '[]'),
    'story_products', coalesce((select jsonb_agg(to_jsonb(sp)) from public.story_video_products sp
                                join public.story_videos v on v.id = sp.video_id where v.seller_id = uid), '[]'),
    'story_likes', coalesce((select jsonb_agg(to_jsonb(l)) from public.story_likes l where l.user_id = uid), '[]'),
    'story_comments', coalesce((select jsonb_agg(to_jsonb(c)) from public.story_comments c where c.user_id = uid), '[]'),
    'story_campaigns', coalesce((select jsonb_agg(to_jsonb(c)) from public.story_campaigns c where c.seller_id = uid), '[]'),
    'security_events_about_you',$q$);
  execute def;
end $$;

-- ---------- Function access -------------------------------------------
revoke execute on function public.protect_story_video(), public.check_story_risk(), public.queue_story_files(),
  public.limit_story_products(), public.sync_story_counters(), public.protect_story_comment(),
  public.check_story_comment_risk(), public.protect_story_campaign(), public.complete_finished_campaigns(),
  public.purge_stories_on_account_deletion()
  from public, anon, authenticated;
revoke execute on function public.admin_activate_campaign(uuid, text), public.admin_reject_campaign(uuid, text),
  public.admin_moderate_story(uuid, public.story_status, text),
  public.get_story_analytics(int), public.get_campaign_analytics(), public.add_story_product_to_cart(uuid, uuid, uuid)
  from public, anon;
grant execute on function public.admin_activate_campaign(uuid, text), public.admin_reject_campaign(uuid, text),
  public.admin_moderate_story(uuid, public.story_status, text),
  public.get_story_analytics(int), public.get_campaign_analytics(), public.add_story_product_to_cart(uuid, uuid, uuid)
  to authenticated;
grant execute on function public.get_story_feed(smallint, int), public.get_story_comments(uuid, int),
  public.seller_follow_info(uuid), public.record_story_event(uuid, public.story_event_type, uuid, uuid),
  public.story_is_public(uuid), public.story_owner(uuid)
  to anon, authenticated;
