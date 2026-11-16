CREATE OR REPLACE FUNCTION public.export_my_data()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  uid uuid := auth.uid();
  result jsonb;
begin
  if uid is null then
    raise exception 'Please sign in first' using errcode = '42501';
  end if;
  if (select count(*) from public.security_events
      where actor_id = uid and action = 'data_exported' and at > now() - interval '24 hours') >= 5 then
    raise exception 'You can download your data 5 times a day. Please try again tomorrow.' using errcode = '54000';
  end if;

  select jsonb_build_object(
    'about_this_file', 'Everything Purple Shop holds about you, as of the time below. Prices are in kobo (100 kobo = 1 naira).',
    'exported_at', now(),
    'account', (select jsonb_build_object('email', u.email, 'phone', u.phone, 'created_at', u.created_at,
                                          'last_sign_in_at', u.last_sign_in_at)
                from auth.users u where u.id = uid),
    'two_factor_methods', coalesce((select jsonb_agg(jsonb_build_object('type', f.factor_type, 'name', f.friendly_name,
                                          'status', f.status, 'created_at', f.created_at))
                from auth.mfa_factors f where f.user_id = uid), '[]'),
    'profile', (select to_jsonb(p) from public.profiles p where p.id = uid),
    'seller_verification', (select jsonb_build_object('status', v.status, 'id_type', v.id_type,
                              'submitted_at', v.submitted_at, 'reviewed_at', v.reviewed_at,
                              'rejection_reason', v.rejection_reason, 'id_file_on_record', v.id_document_deleted_at is null,
                              'id_file_deleted_at', v.id_document_deleted_at, 'bank_name', v.bank_name,
                              'account_name', v.account_name, 'account_last4', v.account_last4)
                from public.seller_verifications v where v.user_id = uid),
    'listings', coalesce((select jsonb_agg(to_jsonb(l) - 'search') from public.listings l where l.seller_id = uid), '[]'),
    'listing_photos', coalesce((select jsonb_agg(to_jsonb(i)) from public.listing_images i
                                join public.listings l on l.id = i.listing_id where l.seller_id = uid), '[]'),
    'saved_items', coalesce((select jsonb_agg(to_jsonb(s)) from public.saves s where s.user_id = uid), '[]'),
    'cart', coalesce((select jsonb_agg(to_jsonb(c)) from public.cart_items c where c.user_id = uid), '[]'),
    'following', coalesce((select jsonb_agg(jsonb_build_object('seller', p.username, 'since', f.created_at))
                           from public.follows f join public.profiles p on p.id = f.seller_id
                           where f.follower_id = uid), '[]'),
    'followers_count', (select count(*) from public.follows f where f.seller_id = uid),
    'buyer_requests', coalesce((select jsonb_agg(to_jsonb(r)) from public.buyer_requests r where r.buyer_id = uid), '[]'),
    'quotes_sent', coalesce((select jsonb_agg(to_jsonb(o)) from public.request_offers o where o.seller_id = uid), '[]'),
    'checkouts', coalesce((select jsonb_agg(to_jsonb(c)) from public.checkouts c where c.buyer_id = uid), '[]'),
    'orders_as_buyer', coalesce((select jsonb_agg(to_jsonb(o)) from public.orders o where o.buyer_id = uid), '[]'),
    'orders_as_seller', coalesce((select jsonb_agg(to_jsonb(o)) from public.orders o where o.seller_id = uid), '[]'),
    'bookings_as_buyer', coalesce((select jsonb_agg(to_jsonb(b)) from public.bookings b where b.buyer_id = uid), '[]'),
    'bookings_as_pro', coalesce((select jsonb_agg(to_jsonb(b) - 'service_address') from public.bookings b where b.pro_id = uid), '[]'),
    'payouts', coalesce((select jsonb_agg(to_jsonb(p)) from public.payouts p where p.seller_id = uid), '[]'),
    'reseller_commissions', coalesce((select jsonb_agg(to_jsonb(c)) from public.reseller_commissions c where c.reseller_id = uid), '[]'),
    'disputes_opened', coalesce((select jsonb_agg(to_jsonb(d) - 'resolved_by') from public.disputes d where d.opened_by = uid), '[]'),
    'reviews_written', coalesce((select jsonb_agg(to_jsonb(r) - 'hidden_by') from public.reviews r where r.reviewer_id = uid), '[]'),
    'reviews_received', coalesce((select jsonb_agg(jsonb_build_object('rating', r.rating, 'body', r.body,
                           'your_reply', r.seller_reply, 'created_at', r.created_at, 'hidden', r.is_hidden))
                           from public.reviews r where r.seller_id = uid), '[]'),
    'conversations', coalesce((select jsonb_agg(jsonb_build_object(
                           'conversation_id', c.id, 'you_are', case when c.buyer_id = uid then 'buyer' else 'seller' end,
                           'messages', coalesce((select jsonb_agg(jsonb_build_object(
                               'from', case when m.sender_id = uid then 'you' else 'the other person' end,
                               'body', m.body, 'sent_at', m.created_at) order by m.created_at)
                             from public.messages m where m.conversation_id = c.id), '[]')))
                           from public.conversations c where uid in (c.buyer_id, c.seller_id)), '[]'),
    'notifications', coalesce((select jsonb_agg(to_jsonb(n)) from public.notifications n where n.recipient_id = uid), '[]'),
    'reports_you_sent', coalesce((select jsonb_agg(jsonb_build_object('reason', r.reason, 'details', r.details,
                           'listing_id', r.listing_id, 'status', r.status, 'created_at', r.created_at))
                           from public.reports r where r.reporter_id = uid), '[]'),
    'referrals', coalesce((select jsonb_agg(to_jsonb(r)) from public.referrals r where uid in (r.referrer_id, r.referred_id)), '[]'),
    'share_links', coalesce((select jsonb_agg(to_jsonb(s)) from public.share_links s where s.created_by = uid), '[]'),
    'stories', coalesce((select jsonb_agg(to_jsonb(v)) from public.story_videos v where v.seller_id = uid), '[]'),
    'story_products', coalesce((select jsonb_agg(to_jsonb(sp)) from public.story_video_products sp
                                join public.story_videos v on v.id = sp.video_id where v.seller_id = uid), '[]'),
    'story_likes', coalesce((select jsonb_agg(to_jsonb(l)) from public.story_likes l where l.user_id = uid), '[]'),
    'story_comments', coalesce((select jsonb_agg(to_jsonb(c)) from public.story_comments c where c.user_id = uid), '[]'),
    'story_campaigns', coalesce((select jsonb_agg(to_jsonb(c)) from public.story_campaigns c where c.seller_id = uid), '[]'),
    'people_you_blocked', coalesce((select jsonb_agg(jsonb_build_object('username', p.username, 'since', b.created_at))
                           from public.user_blocks b join public.profiles p on p.id = b.blocked_id where b.blocker_id = uid), '[]'),
    'seller_record', (select jsonb_build_object('seller_number', 'PS-' || lpad(r.seller_no::text, 6, '0'),
                           'joined_at', r.joined_at, 'status', r.status,
                           'timeline', coalesce((select jsonb_object_agg(m.milestone, m.reached_at) from public.seller_milestones m where m.seller_no = r.seller_no), '{}'),
                           'status_history', coalesce((select jsonb_agg(jsonb_build_object('from', h.from_status, 'to', h.to_status, 'reason', h.reason, 'at', h.changed_at) order by h.changed_at)
                                                         from public.seller_status_history h where h.seller_no = r.seller_no), '[]'))
                         from public.seller_register r where r.seller_id = uid),
    'professional_page', (select jsonb_build_object('type', p.pro_mode, 'public', p.pro_public,
                               'skills', p.skills, 'languages', p.languages, 'cover', p.cover_url,
                               'plan', p.plan, 'plan_expires_at', p.plan_expires_at,
                               'entries', coalesce((select jsonb_agg(to_jsonb(e) - 'owner_id' order by e.kind, e.position)
                                                      from public.pro_entries e where e.owner_id = uid), '[]'))
                             from public.profiles p where p.id = uid),
    'security_events_about_you', coalesce((select jsonb_agg(jsonb_build_object('action', e.action, 'at', e.at) order by e.at)
                           from public.security_events e where e.target_user = uid), '[]')
  ) into result;

  perform public.log_security_event('data_exported', uid, 'profile', uid::text);
  return result;
end $function$
