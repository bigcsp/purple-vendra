-- =====================================================================
-- W6 anonymizer tests. Run on a SEEDED staging/local database.
-- Needs: the anonymizer text in temp table w6_scripts(name = 'anonymize'),
--        and purple.test_target = this project's ref.
-- Everything happens inside blocks that are always rolled back, so the
-- database is left exactly as it was. Results go to w6_results.
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
  v_tab record; v_fk record; v_cnt bigint; v_q text; v_hit text;
  hits text[] := '{}'; orphans text[] := '{}'; fk_checked int := 0;

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
      select 'follows', count(*) from public.follows union all
      select 'pro_entries', count(*) from public.pro_entries
    ) x $q$;
begin
  -- ------------------------------------------------------------ guard refusals (each attempt rolled back on its own)
  begin perform set_config('purple.anonymize_target', '', true); execute script; res := res || 'A01|false|ran without a target';
  exception when others then res := res || ('A01|' || (sqlerrm like 'anonymize refused: set purple.anonymize_target%')::text || '|' || sqlerrm); end;
  begin perform set_config('purple.anonymize_target', 'nozxxxldfthbwhjwbsmy', true); execute script; res := res || 'A02|false|ran with the production ref';
  exception when others then res := res || ('A02|' || (sqlerrm like 'anonymize refused: production%')::text || '|' || sqlerrm); end;
  begin perform set_config('purple.anonymize_target', 'someotherprojectref1', true); execute script; res := res || 'A03|false|ran with a non-matching ref';
  exception when others then res := res || ('A03|' || (sqlerrm like 'anonymize refused: target%does not match%')::text || '|' || sqlerrm); end;
  -- N1: a fragment of the URL, or a partial ref, must not match
  begin perform set_config('purple.anonymize_target', 'supabase', true); execute script; res := res || 'A20|false|ran with a URL fragment as target';
  exception when others then res := res || ('A20|' || (sqlerrm like 'anonymize refused: target%does not match%')::text || '|N1 URL fragment refused: ' || sqlerrm); end;
  begin perform set_config('purple.anonymize_target', left(target, 7), true); execute script; res := res || 'A20b|false|ran with a partial ref';
  exception when others then res := res || ('A20b|' || (sqlerrm like 'anonymize refused: target%does not match%')::text || '|N1 partial ref refused: ' || sqlerrm); end;
  -- missing Vault record
  begin
    delete from vault.secrets where name = 'project_url';
    perform set_config('purple.anonymize_target', target, true);
    execute script;
    res := res || 'A21|false|ran with no Vault project_url';
  exception when others then res := res || ('A21|' || (sqlerrm like 'anonymize refused: Vault project_url is missing%')::text || '|' || sqlerrm); end;
  -- unreadable Vault (role without access)
  begin
    perform set_config('purple.anonymize_target', target, true);
    execute 'set local role authenticated';
    execute script;
    res := res || 'A22|false|ran with Vault unreadable';
  exception when others then res := res || ('A22|' || (sqlerrm like 'anonymize refused: Vault project_url cannot be read%')::text || '|' || sqlerrm); end;
  -- 'local' on a hosted project
  begin perform set_config('purple.anonymize_target', 'local', true); execute script; res := res || 'A23|false|local target accepted on a hosted project';
  exception when others then res := res || ('A23|' || (sqlerrm like 'anonymize refused: target is local%')::text || '|' || sqlerrm); end;

  -- ------------------------------------------------------------ the real run, always rolled back
  begin
    -- storage rows as a real copy could contain them (F3): one ID document, one listing photo, both with uploader metadata
    insert into storage.objects (bucket_id, name, owner_id, metadata, user_metadata)
    select b, p.id || '/w6test-' || f, p.id::text, '{"size": 1}'::jsonb, jsonb_build_object('original_name', o)
    from public.profiles p,
         (values ('id-documents', 'id.jpg', 'passport-scan-adire-house.jpg'),
                 ('listing-images', 'photo.webp', 'shop-front-adire-house.jpg')) v(b, f, o)
    where p.username = 'seed_adire_house';

    create temp table w6_before on commit drop as
      select u.id, u.email, p.display_name, p.username, p.business_name, p.bio, p.referral_code
      from auth.users u join public.profiles p on p.id = u.id;
    create temp table w6_before_text on commit drop as
      select body t from public.messages union all select body from public.story_comments
      union all select coalesce(body, '') from public.reviews union all select message from public.request_offers
      union all select description from public.buyer_requests
      union all select delivery_phone from public.checkouts union all select delivery_address from public.checkouts;
    create temp table w6_ratings on commit drop as select id, rating, seller_id from public.reviews;
    create temp table w6_pro_titles on commit drop as select id, title from public.pro_entries;
    create temp table w6_notes on commit drop as
      select rejection_reason t from public.listings where rejection_reason is not null
      union all select moderation_note from public.story_videos where moderation_note is not null
      union all select rejection_reason from public.seller_verifications where rejection_reason is not null;
    -- every original personal value, for the full sweep (A28)
    create temp table w6_needles on commit drop as
      select distinct kind, v from (
        select 'email' kind, email v from auth.users
        union all select 'display_name', display_name from public.profiles
        union all select 'username', username from public.profiles
        union all select 'business_name', business_name from public.profiles
        union all select 'shop_name_core', btrim(regexp_replace(business_name, '\s*\(seed.*\)$', '')) from public.profiles
        union all select 'buyer_first_name', split_part(display_name, ' ', 1) from public.profiles where role = 'buyer'
        union all select 'headline', headline from public.profiles
        union all select 'bio', bio from public.profiles
        union all select 'referral_code', referral_code from public.profiles
        union all select 'phone', delivery_phone from public.checkouts
        union all select 'address', delivery_address from public.checkouts
        union all select 'address', service_address from public.bookings
        union all select 'delivery_name', delivery_name from public.checkouts
        union all select 'payment_ref', payment_reference from public.checkouts
        union all select 'payout_ref', transfer_reference from public.payouts
        union all select 'id_document_path', id_document_path from public.seller_verifications
        union all select 'bank_account_name', account_name from public.seller_verifications
        union all select 'bank_last4', account_last4 from public.seller_verifications
        union all select 'message', body from public.messages
        union all select 'comment', body from public.story_comments
        union all select 'review', body from public.reviews
        union all select 'review_reply', seller_reply from public.reviews
        union all select 'offer_message', message from public.request_offers
        union all select 'request_description', description from public.buyer_requests
        union all select 'booking_details', job_details from public.bookings
        union all select 'report_details', details from public.reports
        union all select 'pro_entry_title', title from public.pro_entries
        union all select 'admin_note', t from w6_notes
        union all select 'storage_user_metadata', user_metadata ->> 'original_name' from storage.objects
      ) x where v is not null and length(v) >= 4;

    execute counts_sql into c_before;
    select count(*) into search_before from public.search_listings(null::text, null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0);

    perform set_config('purple.anonymize_target', target, true);
    execute script;

    execute counts_sql into c_after;
    res := res || ('A04|' || (c_before = c_after)::text || '|row counts unchanged in 20 tables');
    res := res || ('A05|' || (select count(*) = 0 from auth.users u join w6_before b on b.id = u.id where u.email = b.email)::text || '|no original email remains');
    res := res || ('A06|' || (select bool_and(email like 'user-%@anon.purple.test') from auth.users)::text || '|all emails on the anon .test domain');
    res := res || ('A07|' || (select count(*) = 0 from public.profiles p join w6_before b on b.id = p.id
                              where p.display_name = b.display_name or p.username = b.username
                                 or p.business_name = b.business_name or p.bio = b.bio)::text || '|names, usernames, shop names and bios replaced');
    res := res || ('A08|' || (select count(*) = 0 from public.profiles where username !~ '^[a-z0-9_]{3,30}$')::text || '|usernames still valid; unique index enforced');
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
                              where r.shop_name in (b.business_name, b.display_name) or r.username = b.username)::text || '|seller register snapshot anonymised');
    res := res || ('A14|' || ((select count(*) from auth.mfa_factors) + (select count(*) from auth.sessions)
                              + (select count(*) from auth.refresh_tokens) = 0)::text || '|sessions, refresh tokens and 2FA factors removed');
    res := res || ('A15|' || (select count(*) = 3 and bool_and(tgenabled = 'O') from pg_trigger
                              where tgname in ('reviews_protect', 'security_events_append_only', 'seller_status_history_append_only'))::text
                   || '|protective triggers re-enabled afterwards');
    select count(*) into search_after from public.search_listings(null::text, null::smallint, null::text, null::public.listing_type, null::bigint, null::bigint, 'relevance', 60, 0);
    res := res || ('A16|' || (search_before = search_after and search_after > 0)::text || '|public search returns the same listings (' || search_after || ')');
    res := res || ('A17|' || (select count(*) = 0 from public.security_events where details is not null and details <> '{"anonymised": true}'::jsonb)::text
                   || '|security event details scrubbed');
    -- F1
    res := res || ('A24|' || (select count(*) = 0 from public.profiles p join w6_before b on b.id = p.id where p.referral_code = b.referral_code)::text
                   || '|F1 no original referral code remains');
    res := res || ('A24b|' || (select count(distinct referral_code) = count(*) and bool_and(referral_code ~ '^[0-9a-f]{8}$') from public.profiles)::text
                   || '|F1 new referral codes unique and in the same 8-hex format');
    -- F2
    res := res || ('A25|' || (select count(*) = 0 from public.pro_entries e join w6_pro_titles t on t.id = e.id where e.title = t.title
                              and e.title not in ('Experience entry', 'Education entry', 'Certification entry', 'Achievement entry'))::text
                   || (select '|F2 professional entry titles replaced by a generic title per kind (' || count(*) || ' entries, all generic=' ||
                              bool_and(title in ('Experience entry', 'Education entry', 'Certification entry', 'Achievement entry'))::text || ')' from public.pro_entries));
    -- F3
    res := res || ('A26|' || ((select count(*) from storage.objects where bucket_id = 'id-documents') = 0
                              and (select count(*) from storage.objects where user_metadata is not null) = 0
                              and (select count(*) from storage.objects where bucket_id = 'listing-images' and name like '%/w6test-photo.webp') = 1)::text
                   || '|F3 ID-document storage rows removed; uploader metadata cleared; other object rows kept');
    -- F4
    res := res || ('A27|' || ((select count(*) from w6_notes) > 0 and (select count(*) = 0 from w6_notes n where n.t in (
                                select rejection_reason from public.listings where rejection_reason is not null
                                union all select moderation_note from public.story_videos where moderation_note is not null
                                union all select rejection_reason from public.seller_verifications where rejection_reason is not null)))::text
                   || '|F4 moderation and verification notes replaced (' || (select count(*) from w6_notes) || ' notes)');

    -- F5 / A28: every column of every table in public, private, auth and storage
    for v_tab in select ns.nspname, cl.relname from pg_class cl join pg_namespace ns on ns.oid = cl.relnamespace
                 where cl.relkind in ('r', 'p') and ns.nspname in ('public', 'private', 'auth', 'storage')
                   and cl.relname not in ('schema_migrations', 'migrations') loop
      v_q := format($f$select string_agg(distinct %L || '.' || e.key || ' <- ' || w.kind, '; ')
                       from %I.%I t cross join lateral jsonb_each_text(to_jsonb(t)) e
                       join w6_needles w on e.value = w.v
                          or (w.kind in ('email','display_name','business_name','shop_name_core','buyer_first_name','username','phone','address',
                                         'delivery_name','referral_code','id_document_path','payment_ref','payout_ref','bank_account_name',
                                         'storage_user_metadata')
                              and length(w.v) >= 5 and position(w.v in e.value) > 0)$f$,
                   v_tab.nspname || '.' || v_tab.relname, v_tab.nspname, v_tab.relname);
      execute v_q into v_hit;
      if v_hit is not null then hits := hits || v_hit; end if;
    end loop;
    res := res || ('A28|' || (cardinality(hits) = 0)::text || '|F5 full sweep of every column in public, private, auth, storage; surviving original values: '
                   || coalesce(nullif(array_to_string(hits, ' | '), ''), 'none'));

    -- F5 / A29: every foreign key, every row
    for v_fk in select con.conname, con.conrelid::regclass child, con.confrelid::regclass parent, con.conkey, con.confkey
                from pg_constraint con join pg_namespace ns on ns.oid = con.connamespace
                where con.contype = 'f' and ns.nspname in ('public', 'private', 'auth', 'storage') loop
      select format('select count(*) from %s ch where %s and not exists (select 1 from %s p where %s)', v_fk.child,
               string_agg(format('ch.%I is not null', a.attname), ' and '), v_fk.parent,
               string_agg(format('p.%I = ch.%I', pa.attname, a.attname), ' and '))
        into v_q
        from unnest(v_fk.conkey, v_fk.confkey) as k(ck, pk)
        join pg_attribute a on a.attrelid = v_fk.child and a.attnum = k.ck
        join pg_attribute pa on pa.attrelid = v_fk.parent and pa.attnum = k.pk;
      execute v_q into v_cnt;
      fk_checked := fk_checked + 1;
      if v_cnt > 0 then orphans := orphans || (v_fk.conname || '=' || v_cnt); end if;
    end loop;
    res := res || ('A29|' || (cardinality(orphans) = 0)::text || '|F5 foreign keys checked: ' || fk_checked || '; broken links: '
                   || coalesce(nullif(array_to_string(orphans, ', '), ''), 'none'));

    -- Deterministic and safe to repeat
    create temp table w6_after on commit drop as
      select u.id, u.email, p.display_name, p.username, p.referral_code from auth.users u join public.profiles p on p.id = u.id;
    execute script;
    execute counts_sql into c_again;
    res := res || ('A18|' || (c_again = c_after and (select count(*) = 0 from auth.users u join public.profiles p on p.id = u.id
                              join w6_after a on a.id = u.id
                              where (u.email, p.display_name, p.username, p.referral_code) is distinct from (a.email, a.display_name, a.username, a.referral_code)))::text
                   || '|second run gives the same result');

    raise exception using errcode = 'P0W60', message = 'w6 rollback';
  exception when sqlstate 'P0W60' then
    null;
  end;

  insert into w6_results (suite, name, ok, detail)
  select 'anonymizer', split_part(r, '|', 1), split_part(r, '|', 2)::boolean,
         substr(r, length(split_part(r, '|', 1)) + length(split_part(r, '|', 2)) + 3) from unnest(res) r;
end $test$;

insert into w6_results (suite, name, ok, detail)
select 'anonymizer', 'A19', (select count(*) from auth.users where email like '%@seed.purple.test') = 32
                     and exists (select 1 from vault.secrets where name = 'project_url')
                     and (select count(*) from storage.objects where name like '%/w6test-%') = 0,
       'database unchanged after the test (seed accounts, Vault project_url present, test storage rows gone)';
