-- =====================================================================
-- W6 anonymizer tests. Run on a SEEDED staging/local database.
-- Needs: the anonymizer text in temp table w6_scripts(name = 'anonymize'),
--        and purple.test_target = this project's ref.
-- Everything happens inside a block that is always rolled back at the end,
-- so the database is left exactly as it was. Results go to w6_results.
-- =====================================================================
create temp table if not exists w6_results (n serial, suite text, name text, ok boolean, detail text);
delete from w6_results where suite = 'anonymizer';

do $test$
declare
  script text := (select body from w6_scripts where name = 'anonymize');
  target text := current_setting('purple.test_target');
  res    text[] := '{}';
  c_before jsonb; c_after jsonb; c_again jsonb;
  search_before int; search_after int;
  err text;
  procedure_ok boolean;

  -- counts of every table, to prove nothing is added or lost
  counts_sql constant text := $q$
    select jsonb_object_agg(t, n) from (
      select 'auth.users' t, count(*) n from auth.users union all
      select 'auth.identities', count(*) from auth.identities union all
      select 'profiles', count(*) from public.profiles union all
      select 'listings', count(*) from public.listings union all
      select 'listing_images', count(*) from public.listing_images union all
      select 'messages', count(*) from public.messages union all
      select 'conversations', count(*) from public.conversations union all
      select 'orders', count(*) from public.orders union all
      select 'checkouts', count(*) from public.checkouts union all
      select 'reviews', count(*) from public.reviews union all
      select 'bookings', count(*) from public.bookings union all
      select 'buyer_requests', count(*) from public.buyer_requests union all
      select 'request_offers', count(*) from public.request_offers union all
      select 'story_videos', count(*) from public.story_videos union all
      select 'story_comments', count(*) from public.story_comments union all
      select 'seller_register', count(*) from public.seller_register union all
      select 'seller_verifications', count(*) from public.seller_verifications union all
      select 'saves', count(*) from public.saves union all
      select 'follows', count(*) from public.follows
    ) x $q$;
begin
  -- A1-A3: guards (each attempt is rolled back on its own)
  begin
    perform set_config('purple.anonymize_target', '', true);
    execute script;
    res := res || 'A01|f|ran without a target';
  exception when others then
    res := res || ('A01|' || (sqlerrm like 'anonymize refused: set purple.anonymize_target%')::text || '|' || sqlerrm);
  end;
  begin
    perform set_config('purple.anonymize_target', 'nozxxxldfthbwhjwbsmy', true);
    execute script;
    res := res || 'A02|f|ran with the production ref';
  exception when others then
    res := res || ('A02|' || (sqlerrm like 'anonymize refused: production%')::text || '|' || sqlerrm);
  end;
  begin
    perform set_config('purple.anonymize_target', 'someotherprojectref', true);
    execute script;
    res := res || 'A03|f|ran with a non-matching ref';
  exception when others then
    res := res || ('A03|' || (sqlerrm like 'anonymize refused: target%')::text || '|' || sqlerrm);
  end;

  -- The real run, inside a block that is always rolled back.
  begin
    create temp table w6_before on commit drop as
      select u.id, u.email, p.display_name, p.username, p.business_name, p.bio
      from auth.users u join public.profiles p on p.id = u.id;
    create temp table w6_before_text on commit drop as
      select body t from public.messages union all select body from public.story_comments
      union all select coalesce(body, '') from public.reviews union all select message from public.request_offers
      union all select description from public.buyer_requests
      union all select delivery_phone from public.checkouts union all select delivery_address from public.checkouts;
    create temp table w6_ratings on commit drop as select id, rating, seller_id from public.reviews;

    execute counts_sql into c_before;
    select count(*) into search_before from public.search_listings(null::text, null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0);

    perform set_config('purple.anonymize_target', target, true);
    execute script;

    execute counts_sql into c_after;
    res := res || ('A04|' || (c_before = c_after)::text || '|row counts unchanged in 19 tables');

    res := res || ('A05|' || (select count(*) = 0 from auth.users u join w6_before b on b.id = u.id where u.email = b.email)::text || '|no original email remains');
    res := res || ('A06|' || (select bool_and(email like 'user-%@anon.purple.test') from auth.users)::text || '|all emails on the anon .test domain');
    res := res || ('A07|' || (select count(*) = 0 from public.profiles p join w6_before b on b.id = p.id
                              where p.display_name = b.display_name or p.username = b.username
                                 or p.business_name = b.business_name or p.bio = b.bio)::text || '|names, usernames, shop names and bios replaced');
    res := res || ('A08|' || (select count(*) = 0 from public.profiles where username !~ '^[a-z0-9_]{3,30}$')::text
                   || '|usernames still valid; unique index enforced');
    res := res || ('A09|' || (select count(*) = 0 from auth.identities i join auth.users u on u.id = i.user_id
                              where i.identity_data ->> 'email' is distinct from u.email)::text || '|identity emails match the new emails');
    res := res || ('A10|' || (select count(*) = 0 from w6_before_text b where b.t is not null and b.t <> '' and b.t in (
                                select body from public.messages union all select body from public.story_comments
                                union all select coalesce(body, '') from public.reviews union all select message from public.request_offers
                                union all select description from public.buyer_requests
                                union all select delivery_phone from public.checkouts union all select delivery_address from public.checkouts))::text
                   || '|messages, comments, reviews, offers, request details, phones and addresses replaced');
    res := res || ('A11|' || (select count(*) = 0 from public.reviews r join w6_ratings w on w.id = r.id
                              where r.rating <> w.rating or r.seller_id <> w.seller_id)::text || '|review ratings and links kept');
    res := res || ('A12|' || (select count(*) = 0 from public.seller_verifications
                              where id_document_path is not null or account_last4 <> '0000' or payment_recipient_code is not null)::text
                   || '|ID document paths and bank details removed');
    res := res || ('A13|' || (select count(*) = 0 from public.seller_register r join w6_before b on b.id = r.seller_id
                              where r.shop_name in (b.business_name, b.display_name) or r.username = b.username)::text
                   || '|seller register snapshot anonymised');
    res := res || ('A14|' || ((select count(*) from auth.mfa_factors) + (select count(*) from auth.sessions)
                              + (select count(*) from auth.refresh_tokens) = 0)::text || '|sessions, refresh tokens and 2FA factors removed');
    res := res || ('A15|' || (select bool_and(tgenabled = 'O') from pg_trigger
                              where tgname in ('reviews_protect', 'security_events_append_only'))::text || '|protective triggers re-enabled afterwards');
    select count(*) into search_after from public.search_listings(null::text, null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0);
    res := res || ('A16|' || (search_before = search_after and search_after > 0)::text || '|public search returns the same listings (' || search_after || ')');
    res := res || ('A17|' || (select count(*) = 0 from public.security_events where details is not null and details <> '{"anonymised": true}'::jsonb)::text
                   || '|security event details scrubbed');

    -- Deterministic and safe to repeat: a second run changes nothing.
    create temp table w6_after on commit drop as select u.id, u.email, p.display_name, p.username from auth.users u join public.profiles p on p.id = u.id;
    execute script;
    execute counts_sql into c_again;
    res := res || ('A18|' || (c_again = c_after and (select count(*) = 0 from auth.users u join public.profiles p on p.id = u.id
                              join w6_after a on a.id = u.id where (u.email, p.display_name, p.username) is distinct from (a.email, a.display_name, a.username)))::text
                   || '|second run gives the same result');

    raise exception using errcode = 'P0W60', message = 'w6 rollback';
  exception when sqlstate 'P0W60' then
    null;  -- everything above is undone
  end;

  insert into w6_results (suite, name, ok, detail)
  select 'anonymizer', split_part(r, '|', 1), split_part(r, '|', 2)::boolean, split_part(r, '|', 3) from unnest(res) r;
end $test$;

-- After the rollback the seeded data must be untouched.
insert into w6_results (suite, name, ok, detail)
select 'anonymizer', 'A19 database unchanged after the test (seed emails still present)',
  (select count(*) from auth.users where email like '%@seed.purple.test') = 32, null;
