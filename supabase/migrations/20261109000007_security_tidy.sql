-- =====================================================================
-- Purple Vendra — security tidy-up after step 3 (9 Nov 2026)
-- Fixes from the Supabase security advisor:
-- * Trigger-only functions can no longer be called directly through the
--   API (/rest/v1/rpc/...). Triggers still run them as normal.
-- * Two older functions get a fixed search_path.
-- Intentionally callable: username_available (sign-up form),
-- become_seller (signed-in users), current_role_is (used by access rules).
-- =====================================================================

revoke execute on function public.handle_new_user()                   from public, anon, authenticated;
revoke execute on function public.enforce_home_service_verification() from public, anon, authenticated;
revoke execute on function public.refresh_seller_rating()             from public, anon, authenticated;
revoke execute on function public.validate_review()                   from public, anon, authenticated;

alter function public.set_updated_at() set search_path = '';
alter function public.protect_review() set search_path = '';
