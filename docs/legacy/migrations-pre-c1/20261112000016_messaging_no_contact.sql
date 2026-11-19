-- =====================================================================
-- 016 · Private messaging + "no contact details, escrow only" rules
--
-- 1. contact_problem(text): spots phone numbers (also written as words),
--    emails, links, social/chat apps, @handles and off-platform payment
--    (bank transfer, cash, pay on delivery, payment apps, crypto).
-- 2. Those details are now BLOCKED (not just flagged) in messages,
--    story comments, listings, stories, seller profiles, reviews,
--    buyer requests and quotes. Old text is only checked when edited.
-- 3. Messaging: buyers start a conversation with a seller (optionally
--    about a listing); only the two people in it can read it. All writes
--    go through functions, with rate limits and user blocking.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Detection
-- ---------------------------------------------------------------------
create or replace function public.contact_problem(t text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  s text;
  w text;   -- number words turned into digits
begin
  if t is null or btrim(t) = '' then
    return null;
  end if;
  s := lower(t);

  -- Numbers written as words ("zero eight zero …") count as digits.
  w := regexp_replace(s, '\m(zero|oh)\M', '0', 'g');
  w := regexp_replace(w, '\mone\M', '1', 'g');
  w := regexp_replace(w, '\mtwo\M', '2', 'g');
  w := regexp_replace(w, '\mthree\M', '3', 'g');
  w := regexp_replace(w, '\mfour\M', '4', 'g');
  w := regexp_replace(w, '\mfive\M', '5', 'g');
  w := regexp_replace(w, '\msix\M', '6', 'g');
  w := regexp_replace(w, '\mseven\M', '7', 'g');
  w := regexp_replace(w, '\meight\M', '8', 'g');
  w := regexp_replace(w, '\mnine\M', '9', 'g');

  -- Phone and bank account numbers:
  --   Nigerian mobile in any spacing (0803 123 4567, +234 803…, words),
  --   any 10+ digit run, numbers grouped like 0123 456 789, or +44 7911 123456.
  if regexp_replace(w, '[\s\-\.\(\)/_+]', '', 'g') ~ '(234|0)[789][01][0-9]{8}'
     or regexp_replace(w, '[\-\.\(\)/_]', '', 'g') ~ '[0-9]{10,}'
     or w ~ '[0-9]{3,5}([\s\-\./]+[0-9]{3,5}){2,}'
     or w ~ '\+\s*[0-9]([\s\-\.]?[0-9]){8,}' then
    return 'phone';
  end if;

  if s ~ '[a-z0-9._%+-]+\s*(@|\(at\)|\[at\])\s*[a-z0-9-]+(\.|\s*\(dot\)\s*|\s*\[dot\]\s*| dot )[a-z]{2,}'
     or s ~ '\m(gmail|yahoo|hotmail|outlook|icloud|proton\s*mail|ymail)\M' then
    return 'email';
  end if;

  if s ~ '(https?://|www\.)'
     or s ~ '\m[a-z0-9-]{2,}(\.|\s*\(dot\)\s*|\s*\[dot\]\s*| dot )(com|ng|net|org|io|me|co|link|bio|ly|app|site|store|shop|xyz|info)\M' then
    return 'link';
  end if;

  if s ~ '(whats\s*app|whatsap|watsapp|wats\s*app|wa\.me|\mw/a\M|telegram|t\.me/|\msignal\s*app|instagram|\minsta\M|\mig\M|snap\s*chat|facebook|\mfb\M|messenger|tik\s*tok|twitter|linked\s*in|viber|wechat)'
     or s ~ '(call\s*me|text\s*me|dm\s*me|ping\s*me|reach\s*me\s*(on|at|via)|my\s*(phone|number|line|contact|digits|handle|email|mail|socials?|page))'
     or s ~ '(^|\s)@[a-z0-9_.]{3,}' then
    return 'social';
  end if;

  if s ~ '(account\s*(no|num|number|details?)|acct\s*(no|num)|a/c\s*(no|num)|bank\s*(transfer|details?|account)|\mtransfer\s*(to|into|the\s*money|the\s*payment)|\mpay\s*(me\s*)?(directly|outside|offline|to\s*my|into\s*my|cash)|send\s*(the\s*)?(money|payment|cash)\s*(to|into)|\mcash\M|pay\s*on\s*delivery|payment\s*on\s*delivery|\mpod\M|\mopay\M|palm\s*pay|monie\s*point|\mkuda\M|chipper|paypal|western\s*union|\musdt\M|bitcoin|\mbtc\M|crypto|gift\s*card|\mpos\s*(transfer|payment))' then
    return 'payment';
  end if;

  return null;
end $$;

comment on function public.contact_problem(text) is
  'Returns phone/email/link/social/payment when text tries to move a deal off Purple Shop, else null.';

-- Old helper keeps working for the flag triggers.
create or replace function public.looks_like_off_platform(t text)
returns boolean
language sql
immutable
set search_path = ''
as $$ select public.contact_problem(t) is not null; $$;

create or replace function public.contact_message(kind text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case kind
    when 'phone'   then 'Phone and account numbers can''t be shared on Purple Shop. Keep the chat here so you''re protected.'
    when 'email'   then 'Email addresses can''t be shared on Purple Shop. Keep the chat here so you''re protected.'
    when 'link'    then 'Links to other websites can''t be shared on Purple Shop.'
    when 'social'  then 'WhatsApp, Instagram and other contact handles can''t be shared. Chat on Purple Shop instead.'
    when 'payment' then 'Payments only go through Purple Shop escrow. Bank transfers, cash and payment apps aren''t allowed.'
    else 'That text can''t be shared on Purple Shop.'
  end;
$$;

-- Raises a clear error when text contains contact or payment details.
create or replace function public.forbid_contact(t text)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare k text := public.contact_problem(t);
begin
  if k is not null then
    raise exception '%', public.contact_message(k) using errcode = '22023', hint = 'contact:' || k;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. Block contact details everywhere people type (edits only)
-- ---------------------------------------------------------------------
create or replace function public.block_contact_details()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- The Supabase dashboard / service role is not checked.
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;

  if tg_table_name = 'listings' then
    if tg_op = 'INSERT' or new.title is distinct from old.title or new.description is distinct from old.description then
      perform public.forbid_contact(new.title || ' ' || coalesce(new.description, ''));
    end if;
  elsif tg_table_name = 'story_videos' then
    if tg_op = 'INSERT' or new.title is distinct from old.title or new.description is distinct from old.description then
      perform public.forbid_contact(new.title || ' ' || coalesce(new.description, ''));
    end if;
  elsif tg_table_name = 'story_comments' then
    perform public.forbid_contact(new.body);
  elsif tg_table_name = 'profiles' then
    if new.headline is distinct from old.headline or new.bio is distinct from old.bio
       or new.business_name is distinct from old.business_name or new.display_name is distinct from old.display_name then
      perform public.forbid_contact(concat_ws(' ', new.headline, new.bio, new.business_name, new.display_name));
    end if;
  elsif tg_table_name = 'reviews' then
    if tg_op = 'INSERT' or new.body is distinct from old.body or new.seller_reply is distinct from old.seller_reply then
      perform public.forbid_contact(concat_ws(' ', new.body, new.seller_reply));
    end if;
  elsif tg_table_name = 'buyer_requests' then
    if tg_op = 'INSERT' or new.title is distinct from old.title or new.description is distinct from old.description then
      perform public.forbid_contact(new.title || ' ' || coalesce(new.description, ''));
    end if;
  elsif tg_table_name = 'request_offers' then
    if tg_op = 'INSERT' or new.message is distinct from old.message then
      perform public.forbid_contact(new.message);
    end if;
  elsif tg_table_name = 'service_areas' then
    perform public.forbid_contact(new.city);
  end if;
  return new;
end $$;

create trigger listings_block_contact before insert or update on public.listings
  for each row execute function public.block_contact_details();
create trigger story_videos_block_contact before insert or update on public.story_videos
  for each row execute function public.block_contact_details();
create trigger story_comments_block_contact before insert on public.story_comments
  for each row execute function public.block_contact_details();
create trigger profiles_block_contact before update on public.profiles
  for each row execute function public.block_contact_details();
create trigger reviews_block_contact before insert or update on public.reviews
  for each row execute function public.block_contact_details();
create trigger buyer_requests_block_contact before insert or update on public.buyer_requests
  for each row execute function public.block_contact_details();
create trigger request_offers_block_contact before insert or update on public.request_offers
  for each row execute function public.block_contact_details();
create trigger service_areas_block_contact before insert or update on public.service_areas
  for each row execute function public.block_contact_details();

-- ---------------------------------------------------------------------
-- 3. Messaging
-- ---------------------------------------------------------------------
alter table public.conversations
  add column if not exists last_message_at timestamptz,
  add column if not exists buyer_read_at   timestamptz,
  add column if not exists seller_read_at  timestamptz,
  add column if not exists buyer_archived  boolean not null default false,
  add column if not exists seller_archived boolean not null default false;

create index if not exists conversations_buyer on public.conversations (buyer_id, last_message_at desc);
create index if not exists conversations_seller_recent on public.conversations (seller_id, last_message_at desc);
create index if not exists messages_sender_recent on public.messages (sender_id, created_at desc);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
alter table public.user_blocks enable row level security;
create policy "You can see who you blocked" on public.user_blocks
  for select to authenticated using (blocker_id = (select auth.uid()));

-- Only the two people in a conversation can read it. No direct writes.
create policy "People in a conversation can see it" on public.conversations
  for select to authenticated using ((select auth.uid()) in (buyer_id, seller_id));
create policy "People in a conversation can read its messages" on public.messages
  for select to authenticated using (exists (
    select 1 from public.conversations c
    where c.id = conversation_id and (select auth.uid()) in (c.buyer_id, c.seller_id)));

revoke all on public.conversations, public.messages, public.user_blocks from anon;
revoke insert, update, delete, truncate, references, trigger on public.conversations, public.messages, public.user_blocks from authenticated;
grant select on public.conversations, public.messages, public.user_blocks to authenticated;

create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.user_blocks
                 where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a));
$$;
revoke execute on function public.is_blocked_between(uuid, uuid) from public, anon, authenticated;

-- Belt and braces: messages are checked even if written some other way.
create or replace function public.protect_message()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.body := btrim(new.body);
  perform public.forbid_contact(new.body);
  return new;
end $$;
create trigger messages_protect before insert or update of body on public.messages
  for each row execute function public.protect_message();

-- Start (or reopen) a conversation with a seller. Returns its id.
create or replace function public.start_conversation(p_seller uuid, p_listing uuid default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  conv uuid;
begin
  if uid is null then
    raise exception 'Please sign in to message sellers' using errcode = '42501';
  end if;
  if not public.account_ok(uid) then
    raise exception 'Your account can''t send messages right now' using errcode = '42501';
  end if;
  if p_seller = uid then
    raise exception 'This is your own shop' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles p
                 where p.id = p_seller and p.role in ('seller', 'admin') and public.account_ok(p.id)
                   and p.deletion_requested_at is null) then
    raise exception 'This seller isn''t available' using errcode = 'P0002';
  end if;
  if p_listing is not null and not exists (
       select 1 from public.listings l where l.id = p_listing and l.seller_id = p_seller and l.status = 'approved') then
    raise exception 'That listing isn''t available' using errcode = 'P0002';
  end if;
  if public.is_blocked_between(uid, p_seller) then
    raise exception 'You can''t message this seller' using errcode = '42501';
  end if;

  select c.id into conv from public.conversations c
  where c.buyer_id = uid and c.seller_id = p_seller
    and coalesce(c.listing_id, '00000000-0000-0000-0000-000000000000'::uuid)
      = coalesce(p_listing, '00000000-0000-0000-0000-000000000000'::uuid);
  if conv is not null then
    update public.conversations set buyer_archived = false where id = conv;
    return conv;
  end if;

  if (select count(*) from public.conversations c where c.buyer_id = uid and c.created_at > now() - interval '24 hours') >= 30 then
    raise exception 'You''ve started a lot of chats today. Please try again tomorrow.' using errcode = '54000';
  end if;

  insert into public.conversations (buyer_id, seller_id, listing_id)
  values (uid, p_seller, p_listing)
  returning id into conv;
  return conv;
end $$;

create or replace function public.send_message(p_conversation uuid, p_body text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  c public.conversations;
  other uuid;
  body text := btrim(coalesce(p_body, ''));
  msg uuid;
begin
  if uid is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  select * into c from public.conversations where id = p_conversation;
  if c.id is null or uid not in (c.buyer_id, c.seller_id) then
    raise exception 'Conversation not found' using errcode = 'P0002';
  end if;
  if not public.account_ok(uid) then
    raise exception 'Your account can''t send messages right now' using errcode = '42501';
  end if;
  other := case when uid = c.buyer_id then c.seller_id else c.buyer_id end;
  if public.is_blocked_between(uid, other) then
    raise exception 'You can''t send messages in this chat' using errcode = '42501';
  end if;
  if not public.account_ok(other) or exists (select 1 from public.profiles p where p.id = other and p.deletion_requested_at is not null) then
    raise exception 'This person isn''t available any more' using errcode = '42501';
  end if;
  if char_length(body) = 0 then
    raise exception 'Type a message first' using errcode = '22023';
  end if;
  if char_length(body) > 2000 then
    raise exception 'Messages can be up to 2,000 characters' using errcode = '22023';
  end if;
  perform public.forbid_contact(body);

  if (select count(*) from public.messages m where m.sender_id = uid and m.created_at > now() - interval '1 minute') >= 15
     or (select count(*) from public.messages m where m.sender_id = uid and m.created_at > now() - interval '1 hour') >= 200 then
    raise exception 'You''re sending messages very fast. Please wait a little.' using errcode = '54000';
  end if;

  insert into public.messages (conversation_id, sender_id, body)
  values (c.id, uid, body)
  returning id into msg;

  update public.conversations
  set last_message_at = now(),
      buyer_archived = false,
      seller_archived = false,
      buyer_read_at  = case when uid = buyer_id  then now() else buyer_read_at end,
      seller_read_at = case when uid = seller_id then now() else seller_read_at end
  where id = c.id;
  return msg;
end $$;

create or replace function public.mark_conversation_read(p_conversation uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  update public.messages m set read_at = now()
  from public.conversations c
  where c.id = p_conversation and m.conversation_id = c.id
    and uid in (c.buyer_id, c.seller_id) and m.sender_id <> uid and m.read_at is null;

  update public.conversations
  set buyer_read_at  = case when uid = buyer_id  then now() else buyer_read_at end,
      seller_read_at = case when uid = seller_id then now() else seller_read_at end
  where id = p_conversation and uid in (buyer_id, seller_id);
end $$;

create or replace function public.archive_conversation(p_conversation uuid, p_archived boolean default true)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.conversations
  set buyer_archived  = case when auth.uid() = buyer_id  then p_archived else buyer_archived end,
      seller_archived = case when auth.uid() = seller_id then p_archived else seller_archived end
  where id = p_conversation and auth.uid() in (buyer_id, seller_id);
$$;

create or replace function public.set_user_block(p_user uuid, p_blocked boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  if p_user = uid then
    raise exception 'You can''t block yourself' using errcode = '22023';
  end if;
  if p_blocked then
    insert into public.user_blocks (blocker_id, blocked_id) values (uid, p_user) on conflict do nothing;
    perform public.log_security_event('user_blocked', p_user, 'profile', p_user::text);
  else
    delete from public.user_blocks where blocker_id = uid and blocked_id = p_user;
  end if;
end $$;

-- Inbox: one row per conversation, showing only public names.
create or replace function public.get_inbox(p_archived boolean default false)
returns table (
  id uuid,
  you_are text,
  other_id uuid,
  other_username text,
  other_name text,
  other_avatar text,
  listing_id uuid,
  listing_title text,
  last_message text,
  last_from_you boolean,
  last_message_at timestamptz,
  unread int,
  blocked boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id,
         case when c.buyer_id = auth.uid() then 'buyer' else 'seller' end,
         o.id,
         o.username,
         case when o.role in ('seller', 'admin') then coalesce(o.business_name, o.display_name, o.username) else o.username end,
         o.avatar_url,
         l.id,
         l.title,
         lm.body,
         lm.sender_id = auth.uid(),
         coalesce(c.last_message_at, c.created_at),
         (select count(*)::int from public.messages m
          where m.conversation_id = c.id and m.sender_id <> auth.uid() and m.read_at is null),
         public.is_blocked_between(c.buyer_id, c.seller_id)
  from public.conversations c
  join public.profiles o on o.id = case when c.buyer_id = auth.uid() then c.seller_id else c.buyer_id end
  left join public.listings l on l.id = c.listing_id
  left join lateral (select m.body, m.sender_id from public.messages m
                     where m.conversation_id = c.id order by m.created_at desc limit 1) lm on true
  where auth.uid() in (c.buyer_id, c.seller_id)
    and (case when c.buyer_id = auth.uid() then c.buyer_archived else c.seller_archived end) = p_archived
    and (c.last_message_at is not null or c.buyer_id = auth.uid())
  order by coalesce(c.last_message_at, c.created_at) desc
  limit 200;
$$;

-- One conversation's header details.
create or replace function public.get_conversation(p_conversation uuid)
returns table (
  id uuid,
  you_are text,
  other_id uuid,
  other_username text,
  other_name text,
  other_avatar text,
  other_is_seller boolean,
  listing_id uuid,
  listing_title text,
  listing_price_kobo bigint,
  you_blocked boolean,
  blocked boolean,
  other_available boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id,
         case when c.buyer_id = auth.uid() then 'buyer' else 'seller' end,
         o.id,
         o.username,
         case when o.role in ('seller', 'admin') then coalesce(o.business_name, o.display_name, o.username) else o.username end,
         o.avatar_url,
         o.role in ('seller', 'admin'),
         l.id,
         l.title,
         l.price_kobo::bigint,
         exists (select 1 from public.user_blocks b where b.blocker_id = auth.uid() and b.blocked_id = o.id),
         public.is_blocked_between(c.buyer_id, c.seller_id),
         public.account_ok(o.id) and o.deletion_requested_at is null
  from public.conversations c
  join public.profiles o on o.id = case when c.buyer_id = auth.uid() then c.seller_id else c.buyer_id end
  left join public.listings l on l.id = c.listing_id
  where c.id = p_conversation and auth.uid() in (c.buyer_id, c.seller_id);
$$;

create or replace function public.unread_message_count()
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int
  from public.messages m
  join public.conversations c on c.id = m.conversation_id
  where auth.uid() in (c.buyer_id, c.seller_id)
    and m.sender_id <> auth.uid() and m.read_at is null
    and (case when c.buyer_id = auth.uid() then c.buyer_archived else c.seller_archived end) = false;
$$;

revoke execute on function public.start_conversation(uuid, uuid), public.send_message(uuid, text),
  public.mark_conversation_read(uuid), public.archive_conversation(uuid, boolean),
  public.set_user_block(uuid, boolean), public.get_inbox(boolean), public.get_conversation(uuid),
  public.unread_message_count() from public, anon;
grant execute on function public.start_conversation(uuid, uuid), public.send_message(uuid, text),
  public.mark_conversation_read(uuid), public.archive_conversation(uuid, boolean),
  public.set_user_block(uuid, boolean), public.get_inbox(boolean), public.get_conversation(uuid),
  public.unread_message_count() to authenticated;

-- Data export: rename + include blocks.
do $$
declare d text;
begin
  d := pg_get_functiondef('public.export_my_data()'::regprocedure);
  d := replace(d, 'Everything Purple Vendra holds', 'Everything Purple Shop holds');
  d := replace(d, '''security_events_about_you'',',
    '''people_you_blocked'', coalesce((select jsonb_agg(jsonb_build_object(''username'', p.username, ''since'', b.created_at))
                           from public.user_blocks b join public.profiles p on p.id = b.blocked_id where b.blocker_id = uid), ''[]''),
    ''security_events_about_you'',');
  execute d;
end $$;
