-- =====================================================================
-- W6 seed checks. Read-only: run after supabase/seed.sql on staging or local.
-- Writes one row per check into the session temp table w6_results
-- (name, ok, detail). Every row must have ok = true.
-- =====================================================================
create temp table if not exists w6_results (n serial, suite text, name text, ok boolean, detail text);
delete from w6_results where suite = 'seed';

insert into w6_results (suite, name, ok, detail)
-- Accounts and personas
select 'seed', 'S01 32 seed accounts, all on the reserved .test domain',
  count(*) = 32 and bool_and(email like '%@seed.purple.test'), count(*)::text from auth.users
union all
select 'seed', 'S02 roles: 1 admin, 12 buyers, 19 sellers',
  count(*) filter (where role = 'admin') = 1 and count(*) filter (where role = 'buyer') = 12 and count(*) filter (where role = 'seller') = 19,
  string_agg(distinct role::text, ',') from public.profiles
union all
select 'seed', 'S03 every account has an email identity and a password hash',
  (select count(*) from auth.identities where provider = 'email') = 32
  and (select count(*) from auth.users where encrypted_password is null or encrypted_password = '') = 0, null
union all
select 'seed', 'S04 personas: product sellers, freelancers, home-service pros, creatives',
  count(distinct l.seller_id) filter (where l.type = 'product' and l.category_id in (1, 2)) >= 5
  and count(distinct l.seller_id) filter (where l.type = 'service' and l.category_id in (3, 5)) >= 4
  and count(distinct l.seller_id) filter (where l.category_id = 6) >= 4
  and count(distinct l.seller_id) filter (where l.type = 'talent') >= 3,
  format('product=%s freelance=%s home=%s talent=%s',
    count(distinct l.seller_id) filter (where l.type = 'product' and l.category_id in (1, 2)),
    count(distinct l.seller_id) filter (where l.type = 'service' and l.category_id in (3, 5)),
    count(distinct l.seller_id) filter (where l.category_id = 6),
    count(distinct l.seller_id) filter (where l.type = 'talent')) from public.listings l
union all
select 'seed', 'S05 every seller is in the seller register', count(*) = 19, count(*)::text
from public.seller_register r join public.profiles p on p.id = r.seller_id where p.role = 'seller'
union all
-- Listings
select 'seed', 'S06 all listing types approved and live (product, service, talent)',
  count(distinct type) filter (where status = 'approved') = 3, string_agg(distinct type::text, ',') from public.listings
union all
select 'seed', 'S07 all listing statuses present (draft, pending, approved, rejected, removed)',
  count(distinct status) = 5, string_agg(distinct status::text, ',') from public.listings
union all
select 'seed', 'S08 every category has an approved listing',
  (select count(distinct category_id) from public.listings where status = 'approved') = (select count(*) from public.categories), null
union all
select 'seed', 'S09 all five delivery modes used', count(distinct delivery_mode) = 5, string_agg(distinct delivery_mode::text, ',') from public.listings
union all
select 'seed', 'S10 home-service listings that are pending/approved have an approved ID check',
  count(*) = 0, count(*)::text from public.listings l
  where l.category_id = 6 and l.status in ('pending', 'approved')
    and not exists (select 1 from public.seller_verifications v where v.user_id = l.seller_id and v.status = 'approved')
union all
select 'seed', 'S11 verified badge matches approved ID checks',
  count(*) = 0, count(*)::text from public.profiles p
  where p.is_verified is distinct from exists (select 1 from public.seller_verifications v where v.user_id = p.id and v.status = 'approved')
union all
select 'seed', 'S12 rejected listings carry a reason', count(*) = 0, count(*)::text
from public.listings where status = 'rejected' and rejection_reason is null
union all
select 'seed', 'S13 media paths sit in the owner''s folder (listing images, stories)',
  (select count(*) from public.listing_images i join public.listings l on l.id = i.listing_id where i.storage_path not like l.seller_id::text || '/%') = 0
  and (select count(*) from public.story_videos where video_path not like seller_id::text || '/%' or thumbnail_path not like seller_id::text || '/%') = 0, null
union all
-- Professional pages
select 'seed', 'S14 public pro pages: sellers with a mode only; both modes represented',
  count(*) filter (where pro_public and (role <> 'seller' or pro_mode is null)) = 0
  and count(*) filter (where pro_public and pro_mode = 'professional') >= 1
  and count(*) filter (where pro_public and pro_mode = 'creative_space') >= 1,
  format('public=%s', count(*) filter (where pro_public))
from public.profiles
union all
-- Stories
select 'seed', 'S15 story statuses published, draft and hidden present',
  count(distinct status) = 3, string_agg(distinct status::text, ',') from public.story_videos
union all
select 'seed', 'S16 story like/comment counters match the rows',
  count(*) = 0, count(*)::text from public.story_videos v
  where v.like_count <> (select count(*) from public.story_likes l where l.video_id = v.id)
     or v.comment_count <> (select count(*) from public.story_comments c where c.video_id = v.id)
union all
select 'seed', 'S17 tagged story products belong to the story''s seller, at most 6',
  count(*) = 0, count(*)::text from public.story_video_products p
  join public.story_videos v on v.id = p.video_id join public.listings l on l.id = p.listing_id
  where l.seller_id <> v.seller_id
     or (select count(*) from public.story_video_products x where x.video_id = p.video_id) > 6
union all
-- Requests
select 'seed', 'S18 request statuses open, closed and expired present',
  count(distinct status) = 3, string_agg(distinct status::text, ',') from public.buyer_requests
union all
select 'seed', 'S19 request offer_count = live offers; accepted offer belongs to the request',
  count(*) = 0, count(*)::text from public.buyer_requests r
  where r.offer_count <> (select count(*) from public.request_offers o where o.request_id = r.id and o.status in ('sent', 'accepted'))
     or (r.accepted_offer_id is not null and not exists (
          select 1 from public.request_offers o where o.id = r.accepted_offer_id and o.request_id = r.id and o.status = 'accepted'))
union all
select 'seed', 'S20 all offer statuses present (sent, accepted, declined, withdrawn)',
  count(distinct status) = 4, string_agg(distinct status::text, ',') from public.request_offers
union all
-- Messaging
select 'seed', 'S21 conversations: 2+ messages each, senders are participants',
  count(*) = 0, count(*)::text from public.conversations c
  where (select count(*) from public.messages m where m.conversation_id = c.id) < 2
     or exists (select 1 from public.messages m where m.conversation_id = c.id and m.sender_id not in (c.buyer_id, c.seller_id))
union all
-- Orders, bookings, reviews
select 'seed', 'S22 reviews only from completed orders or bookings by the customer',
  count(*) = 0, count(*)::text from public.reviews r
  where not exists (select 1 from public.orders o where o.id = r.order_id and o.status = 'completed' and o.buyer_id = r.reviewer_id and o.seller_id = r.seller_id)
    and not exists (select 1 from public.bookings b where b.id = r.booking_id and b.status = 'completed' and b.buyer_id = r.reviewer_id and b.pro_id = r.seller_id)
union all
select 'seed', 'S23 seller ratings equal the average of visible reviews',
  count(*) = 0, count(*)::text from public.profiles p
  where exists (select 1 from public.reviews r where r.seller_id = p.id)
    and (p.rating_avg, p.rating_count) is distinct from
        (select round(avg(rating)::numeric, 1), count(*)::int from public.reviews r where r.seller_id = p.id and not r.is_hidden)
union all
select 'seed', 'S24 every completed order has a payout of the seller''s share',
  count(*) = 0, count(*)::text from public.orders o
  where o.status = 'completed' and not exists (select 1 from public.payouts y where y.order_id = o.id and y.amount_kobo = o.seller_payout_kobo)
union all
-- Content rules
select 'seed', 'S25 no seeded text trips the contact-details rule',
  count(*) = 0, coalesce(string_agg(src, '; '), 'none') from (
    select 'listing:' || title src, title || ' ' || description t from public.listings
    union all select 'story:' || title, title || ' ' || coalesce(description, '') from public.story_videos
    union all select 'comment', body from public.story_comments
    union all select 'message', body from public.messages
    union all select 'request:' || title, title || ' ' || description from public.buyer_requests
    union all select 'offer', message from public.request_offers
    union all select 'review', concat_ws(' ', body, seller_reply) from public.reviews
    union all select 'profile:' || username, concat_ws(' ', display_name, business_name, headline, bio, array_to_string(skills || languages, ' ')) from public.profiles
    union all select 'pro_entry', concat_ws(' ', title, organisation, location, description) from public.pro_entries
    union all select 'service_area', city from public.service_areas
  ) x where public.contact_problem(t) is not null
union all
-- Test-case accounts
select 'seed', 'S26 test-case accounts: banned, suspended buyer, suspended shop, pending deletion',
  count(*) filter (where account_status = 'banned') = 1
  and count(*) filter (where account_status = 'suspended' and role = 'buyer') = 1
  and count(*) filter (where account_status = 'suspended' and role = 'seller') = 1
  and count(*) filter (where deletion_requested_at is not null) = 1, null
from public.profiles
union all
-- What the public sees (functions the website calls)
select 'seed', 'S27 public search hides suspended shops and unapproved listings',
  (select count(*) from public.search_listings(null::text, null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0) s
     where s.seller_id in (select id from public.profiles where not public.account_ok(id))
        or s.id in (select id from public.listings where status <> 'approved')) = 0
  and (select count(*) from public.search_listings('adire', null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0)) >= 1,
  null
union all
select 'seed', 'S28 public request board lists exactly the open requests',
  (select count(*) from public.get_request_board(null::text, null::smallint, null::text, false, 50, 0))
  = (select count(*) from public.buyer_requests where status = 'open'), null
union all
-- Nothing real
select 'seed', 'S29 no email addresses outside the .test domains anywhere in seeded text',
  count(*) = 0, count(*)::text from (
    select description t from public.listings union all select body from public.messages
    union all select coalesce(bio, '') from public.profiles union all select description from public.buyer_requests
  ) x where t ~* '[a-z0-9._%+-]+@[a-z0-9-]+\.[a-z]{2,}' and t !~* '@[a-z.]*purple\.test'
union all
select 'seed', 'S30 checkout phone numbers are the zero test range',
  count(*) = 0, count(*)::text from public.checkouts where delivery_phone !~ '^\+2340000000[0-9]{3}$';
