# Purple Shop — Phase 1 Technical Audit

**Brief:** Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0 (16 Nov 2026)
**Audited:** repo `bigcsp/purple-vendra` @ `d7a0011` (14 Nov 2026) + live Supabase project `PURPLE VENDRA` (read-only queries)
**Date:** 16 Nov 2026 · **Status:** awaiting owner approval. No application code or database changes were made.

Labels used: **[Fact]** = verified in code or the live database. **[Assumption]** = my inference, needs confirming.

---

## 1. Summary

Purple Shop is in good shape to extend. The stack is small and consistent: Next.js 16 on Vercel (London), Supabase for everything else. Most business rules are enforced inside Postgres (row-level security, triggers, functions), which is the right place for quotas and payment checks. Much of what the brief needs already exists in some form: a `story_campaigns` promote flow, `featured_purchases`, `featured_until` on listings, a free/premium plan flag, anonymous analytics events, and messaging for enquiries.

Five issues need to be fixed or decided before Phase 2 starts:

1. **The repo can't rebuild the database.** Migration 011 is missing, the live DB holds four migrations that have no matching files, and the `storage-cleanup` Edge Function isn't in the repo.
2. **There's no payment provider.** No Paystack code, keys, webhook or payment table exists. `src/server/services/` is empty.
3. **The video quota can be bypassed.** Storage uploads aren't counted, deleting a story gives the slot back, and video duration is reported by the browser and not checked by the server.
4. **There's no admin screen.** Every approval (IDs, listings, campaigns, Premium) is done by hand in the SQL editor.
5. **There are no automated tests and no staging environment.** Every migration goes straight to the production database.

## 2. Current architecture [Fact]

| Layer | What exists |
|---|---|
| Frontend | Next.js 16.4.5 App Router, React 19.3, Tailwind v4, `cacheComponents`. Mobile-first, PWA (manifest, service worker, offline page). |
| Backend | `src/server/` holds server actions, queries and `/api/*` route logic, guarded by `server-only`. It always uses the **signed-in user's** Supabase session. There's no service-role key anywhere. |
| Database | Supabase Postgres 17, London (eu-west-2). 22 migration files, about 50 tables, RLS on every table, about 120 functions. |
| Auth | Supabase Auth with email confirmation. Roles: `buyer`, `seller`, `admin`. Sellers and admins need TOTP 2FA (`aal2`) to post, enforced by `can_post()` in the DB. |
| Storage | Buckets: `listing-images` (public), `id-documents` (private), `story-media` (public, 50 MB/file, mp4/webm/mov + images). |
| Video processing | **In the browser**: ffmpeg.wasm transcodes to H.264 720p MP4 and the cover image is made in the browser. Server processing cost is zero. |
| Scheduled jobs | pg_cron: `story-campaigns-complete` (hourly), `requests-expire` (hourly), `privacy-retention` (nightly), `storage-cleanup` (nightly; calls an Edge Function). |
| Deploy | Vercel (`lhr1`) from GitHub. CI runs lint, type check, build and `npm audit`. **No tests.** |
| Live data | 7 profiles, 1 seller, 1 listing, 1 story, 0 campaigns, 0 featured purchases, about 13 MB of video. Pre-launch. |

## 3. What can be reused

| Brief need | Existing asset | Verdict |
|---|---|---|
| Free sign-up and storefront | Sign-up, `become_seller`, shop page `/shop/[u]`, `/sell/profile` | **Reuse as is.** Joining is already free. |
| Professional profile / Creative Space | `/pro/[username]`, `pro_entries`, `pro_mode` (migration 022) | **Reuse.** |
| Enquiries | `conversations`/`messages`, `start_conversation`, contact-details guard | **Reuse.** Enquiry counts can come from conversations. |
| Free vs paid plan | `profiles.plan` (`free`/`premium`), `plan_expires_at`, `is_premium()`, protected from self-edit | **Extend.** Founding flags go next to it. |
| Video upload | `story_videos` + `story-media` + browser transcode + moderation + reports (3 reports auto-hide) | **Reuse; fix the quota (§5).** |
| Video promotion | `story_campaigns` (budget ₦1k–₦1M, audience, admin activation, hourly expiry, impression/click attribution) | **Partly reuse.** The analytics and expiry parts carry over. The variable-budget model doesn't match the brief's fixed 7-day packages. |
| Listing boost | `listings.featured_until` (sellers can't set it themselves) + search ranks featured first + `featured_purchases` (unused, listings only) | **Reuse `featured_until` for ranking.** Replace `featured_purchases` with a general promotions table (0 rows, safe). |
| Payment record | `checkouts`, `orders`, `payouts` (built for escrow; unused) | **Don't reuse for promotions.** Promotions need their own payments ledger. |
| Admin actions | `admin_activate_campaign`, `admin_moderate_story`, `admin_review_queue`, `admin_set_account_status`, audit log `security_events` | **Reuse the functions; build screens on top.** |
| Metrics | `story_events` (impression/view/share/product_click/shop_visit/add_to_cart, with campaign ID), `get_campaign_analytics()` | **Reuse and generalise.** |
| Listing metrics | `listing_events` table | **Gap:** the app never writes to it, so listing views aren't tracked today. |

## 4. Gaps against the brief

1. **Payments.** Nothing is integrated. The README names Paystack, but it isn't built. We need a provider account, a server-only secret key, a webhook route with signature verification, an idempotent `confirm_payment` DB function, and a `payments` ledger.
2. **Server-side trusted writer.** Webhooks have no signed-in user, so we need either a `SUPABASE_SECRET_KEY` (service role) used only in `src/server/services/`, or a dedicated DB role. The current design deliberately has neither, so this needs your approval.
3. **Configurable settings.** Prices, durations, quotas and founding dates are hard-coded in triggers (e.g. "10 stories a day", "₦1,000–₦1,000,000"). We need an admin-editable `platform_settings` table and a `promotion_packages` table.
4. **Admin UI.** There's no `/admin` route. Phases 3 and 4 both need one (packages, payment checks, campaign review). This isn't in the brief's phase list, so I've added it as a dependency.
5. **Enquiry tracking.** The Message button is already on shop, listing and `/pro` pages **[Fact]**. Conversations aren't tagged with where they started, so "enquiries from a promotion" can't be measured yet. Phase 3 adds a source/promotion tag to `start_conversation`.

## 5. Risks (most serious first)

| # | Risk | Evidence [Fact] | Proposed fix |
|---|---|---|---|
| R1 | **Database drift**: the repo can't reproduce production | `011` file missing (it defines `queue_file_deletion`, `account_status`, `run_privacy_retention`, `storage_deletion_queue`). Live-only migrations: `search_word_similarity`, `messaging_lock_block_helper`, `request_reports_keep_buyer_hidden`, `request_reports_escalation`. `storage-cleanup` Edge Function source isn't in the repo. Live history starts at 012; 001–011 were run by hand. | Export the live definitions into repo migrations, add the Edge Function source, and baseline migration history. |
| R2 | **Video quota bypass** | The `story-media` insert policy only checks "own folder + 2FA", so files can be uploaded without ever creating a story row. The quota counts `story_videos` rows from the last 24h, so **deleting gives the slot back**. `duration_seconds` comes from the browser, can be null, and the DB accepts up to 180s; the 90s limit exists only in the browser. | **Upload tickets**: a server action reserves a slot in an `upload_ledger` row that the user can't delete, then the storage policy only allows a path that has a matching unused ticket. Make duration required. Lower the per-file size limit (about 25 MB is plenty for 60s at 720p). Verify duration on the server from the MP4 header in the existing Edge Function, and hide the video if it doesn't match. |
| R3 | **Orphaned storage files** | Cleanup only removes files queued by triggers. Files uploaded without a story row are never removed. | A nightly sweep in `storage-cleanup` for files that have no story or ticket and are older than 24h. |
| R4 | **No payments; activation is manual** | `admin_activate_campaign` trusts any reference text an admin types. | Activate only through `confirm_payment()` after webhook signature check + provider verify API + amount/currency match + unique reference. |
| R5 | **Hosting limits** | The Supabase Free plan includes 1 GB of file storage and 5 GB of egress. Live usage is 13 MB. Video is public, so every view uses egress. | Free quota (3×60s ≈ 15 MB per seller per month) means about 60 active video sellers fill 1 GB in a month. **Plan the Supabase Pro upgrade before launch** (250 GB egress, overage $0.09/GB). Add a usage dashboard query. |
| R6 | **No staging; no tests** | One Supabase project serves both dev and production. CI has no tests. | Second Supabase project as staging. pgTAP SQL tests for quotas, payments and RLS. Playwright smoke tests against Vercel preview. |
| R7 | **Two overlapping promotion models** | `story_campaigns` (budget-based) vs the brief's fixed packages. | Decision needed (§8 D1). |
| R8 | Minor security hygiene | Advisors: leaked-password protection off; `limit_saves()` trigger function callable via RPC; `pg_trgm` in the public schema. The other "SECURITY DEFINER executable" warnings are intentional RPCs with internal checks. | Fix in the Phase 2 foundation migration. |
| R9 | Docs are stale | The README says stories are "up to 90 seconds" and "10 a day"; the brief proposes 3 per month and 60s. The README still says "Purple Vendra" in places. | Update the README with each phase. |

## 6. Proposed implementation plan

**Phase 1b: Foundation** (new; about 2–3 days; does what the brief requires before building)
- Bring all live DB objects (011 + the 4 live-only migrations) and the `storage-cleanup` function into the repo, and confirm a clean rebuild on staging.
- Create a staging Supabase project and a Vercel preview environment pointed at it. Add `PROJECT_STATUS.md` (done).
- Add a test harness: pgTAP (DB rules), Vitest (pure helpers), Playwright (smoke tests).
- Fix the advisor hygiene items.

**Phase 2: Founding Free Plan + video limits** (3–5 days)
- `platform_settings` (single row, admin-only): `founding_starts_at`, `founding_ends_at`, `video_monthly_quota=3`, `video_max_seconds=60`, `video_max_bytes`, `listing_limit_free`, `quota_timezone='Africa/Lagos'`.
- `profiles.founding_member boolean`, set for anyone who joins during the founding window. No billing is touched; no auto-charge is possible because there's no stored card.
- `upload_ledger` + `reserve_video_upload()` RPC: checks the monthly quota, writes the ticket, and returns the allowed path. The storage policy requires the ticket. The story insert consumes the ticket. Deletion doesn't refund it.
- Replace the hard-coded "10 a day" with the settings value. Make duration required and capped from settings. Lower the bucket size limit.
- Seller UI: remaining quota, reset date, clear errors. Founding badge/explainer.
- Edge Function: verify MP4 duration after upload and sweep orphaned files.

**Phase 3: Featured Promotions** (5–8 days, plus about 2 days for the minimal admin screens)
- Tables: `promotion_packages` (admin-configurable price/duration/target type/active), `promotions` (target_type ∈ product/service/profile/pro_page/storefront/video, target_id, status ∈ pending_payment/active/paused/expired/rejected/refunded/failed, starts/ends), `payments` (provider, reference UNIQUE, amount_kobo, status, raw event), `payment_events` (webhook ID UNIQUE, for idempotency).
- Paystack: initialise on the server → redirect → **the webhook is the only thing that activates** (HMAC-SHA512 signature + verify-transaction call + amount match). The redirect page just shows the status.
- Placement: search/category ranking reads active promotions (and sets `featured_until` for listings). The story feed reads `promotions` for videos. Shop/pro pages get a "Featured" strip. Everything is labelled **Sponsored**.
- Expiry through the existing hourly cron pattern. Renewal = a new purchase that chains `starts_at`.
- Minimal `/admin` (admin + 2FA): packages, payments, promotions, refunds (manual refund marking first).

**Phase 4: Purple Business Campaigns** (7–12 days): `business_campaigns` with objective, creative (private bucket until approved), destination URL (on-platform or allow-listed), schedule, package, status flow `submitted → paid → in_review → approved/rejected(reason) → live → paused → completed`. Reuses `payments` and `/admin`. Reports only tracked events.

**Phase 5:** unchanged from the brief; each feature gets its own scope.

## 7. Test strategy

| Level | Tool | Must cover |
|---|---|---|
| DB rules | pgTAP on staging/local | Quota at 3/month, deletion doesn't refund, month reset in Lagos time, storage insert rejected without a ticket, sellers can't self-activate promotions, double webhook gives one activation, wrong amount gives no activation, RLS on every new table. |
| Unit | Vitest | Price/money helpers, settings parsing, webhook signature check. |
| E2E | Playwright on Vercel preview + staging DB | Sign up → seller → 2FA → listing → story (within quota, over quota) → enquiry. Buy a boost with Paystack **test mode** → webhook → Sponsored placement visible → expiry. |
| Regression | Playwright smoke | Home, search, listing, shop, /pro, stories feed, cart, messages, requests. |
| Ops | SQL dashboard queries | Storage bytes, monthly uploads, failed payments, promotions by status. |

Nothing is called "done" without these passing on staging. Production migrations run only after staging passes.

## 8. Decisions needed from you

| # | Decision | My recommendation |
|---|---|---|
| D1 | Existing `story_campaigns` (budget-based) vs fixed 7-day Video Promotion | Stop creating new budget campaigns. Video Promotion becomes a `promotions` package. Keep old rows readable (there are 0 today). |
| D2 | Payment provider | **Paystack** (already named in the README, NGN, has webhooks + verify API). You'll need an account and test keys. |
| D3 | Server secret key for webhooks | Allow `SUPABASE_SECRET_KEY` in Vercel env, used **only** in `src/server/services/payments`. |
| D4 | Official launch date (starts the 6-month founding window) | Needed before Phase 2 ships; can be set later in settings. |
| D5 | Staging environment | A second free Supabase project. Your other free slot is the paused Crop AI project, so it may need deleting or you'll need Pro. |
| D6 | Supabase Pro upgrade timing | Before public launch with video (R5). |
| D7 | Existing 10-stories-a-day rule for current sellers | Replace with 3/month for everyone. Premium could get more later. |
| D8 | Brief's open items (§11): Nigeria-first, 6 months, basic stays free, 3×60s, campaign self-serve + approval, auto-activate promotions after payment | All look sound. Please confirm. |

## 9. Next step

Approve this audit, answer D1–D8, and I'll start **Phase 1b (Foundation)**, then stop again before Phase 2.
