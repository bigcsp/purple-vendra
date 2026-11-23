# Purple Shop — Product Expansion & Integration Plan

**Directive:** *Purple Shop Product Expansion & Project Integration Directive* (23 Nov 2026)
**Inspected:** `main` @ `d7a0011` and `phase-1b-foundation` @ `c72978a` (26 migrations, ~50 tables incl. storage queues, 139 function definitions), plus existing docs (`PHASE-1-AUDIT.md`, `PHASE-1B-PLAN.md` v1.2, ADR-001/002).
**Status:** **Proposed — awaiting owner review.** Docs only. No application code, migrations, dependencies or databases were changed. Phase 1b (W7 next) stays the immediate priority.

Companion documents: [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`FEATURE-MAP.md`](FEATURE-MAP.md) · [`ROADMAP.md`](ROADMAP.md) · [`decisions/ADR-003-product-expansion-integration.md`](decisions/ADR-003-product-expansion-integration.md)

Labels: **[Fact]** verified in code or schema · **[Assumption]** needs confirming · **[Proposal]** my recommendation.

---

## 1. Summary

The twelve proposed modules are **not twelve new systems**. Seven of them already exist in full or in part, and most of the rest are new *views* over tables that are already in the schema:

| | Modules |
|---|---|
| **Built, needs upgrades** | Purple Stories, Purple Request, Purple Professional (step 1) |
| **Partly built** | Purple Discover, Purple Business Studio, Purple Business Spotlight, My Purple World, Purple Rewards (schema only) |
| **New** | Purple Deals, Purple Match, Purple Community, Purple Live |

Of the supporting features, **shop following** and **wishlists (Saved)** work today; **bookings**, **customer reviews** and **notifications** have finished tables and rules but no screens; **seller analytics** exists for stories only; **price alerts**, **restock alerts** and **personalised recommendations** are new.

Three shared foundations decide almost everything else. Building them once, before the modules, avoids duplicate systems:

1. **Checkout & escrow (backend step 7, Paystack via Edge Functions, decision O3).** Bookings, reviews, Deals, Rewards, paid Spotlight and any Live tipping all need a real completed payment.
2. **A notification centre** on the existing, unused `notifications` table. Following, price/restock alerts, request offers, bookings and Deals all deliver through it.
3. **One activity-event model**, generalising the anonymous `story_events` pattern and finally writing the unused `listing_events`. Seller analytics, Discover ranking, Spotlight reporting and Match all read from it.

**Recommended order** (detail in §6 and `ROADMAP.md`): finish Phase 1b → Phase 2 + the three foundations → checkout & escrow → My Purple World, Business Studio, alerts, Discover v1 → promotions/Spotlight (Phase 3) → bookings, reviews, Match, Professional 2–3 → Deals → Rewards → Community → Live (spike first).

## 2. What already exists [Fact]

| Area | Where it lives today |
|---|---|
| Accounts & roles | `profiles` (buyer/seller/admin), sign-up/login, TOTP 2FA (`aal2`) enforced by `can_post()` in the DB, suspend/ban (`account_status`) |
| Seller identity | Shop page `/shop/[username]` + `/sell/profile`; professional page `/pro/[username]` + `/sell/pro` (both views of the same `profiles` row); ID verification + verified badge; permanent `seller_register` |
| Catalogue | `listings` (product/service/talent, `stock`, `featured_until`), images, 3 sections × 6 categories, home-service ID rule |
| Discovery | `/search` (full-text, typo-tolerant, synonyms, suggestions, did-you-mean, popular searches), `/c/[slug]` category pages, homepage, local-only "Recently viewed" |
| Purple Stories | Upload (browser ffmpeg), gallery, `/stories` feed, likes, comments, shop-the-video, analytics, budget campaigns (admin-activated) |
| Purple Requests | Public board, offers (max 10), accept → private chat, 14-day expiry cron |
| Messaging | `conversations`/`messages` via RPCs, contact-details blocker, user blocks, unread count |
| Saved & cart | `saves` (500 cap, sellers see counts only), `cart_items`, `follows` (follow button on stories/shop) |
| Money (schema only) | `checkouts`, `orders`, `order_items`, `payouts`, `disputes`, `reseller_commissions`, `featured_purchases` — no payment provider yet |
| Trust & safety | Reports (3 established reporters auto-hide), `risk_flags`, `security_events` audit log, privacy export/deletion, retention cron |
| Unused but ready | `notifications`, `bookings`, `reviews` (+ validation, owner reply, rating refresh), `referrals` + `profiles.referral_code`, `share_links`, `content_features` (Meet the Maker), `listing_events`, `working_hours`, `service_areas` (used by shop page) |

## 3. Module-by-module integration

Each module: **exists → upgrade → add → where it belongs → connects to**. "Belongs" uses the current three-part layout (`src/app` website, `src/server` backend, `supabase/` database).

### 3.1 Purple Discover — *partly built*
- **Exists:** homepage, search stack (migrations 014/018), category pages, stories feed with promoted-first ranking, popular searches, local recently-viewed.
- **Upgrade:** homepage becomes Discover: sections for *Trending this week*, *New from shops you follow*, *Because you saved…*, *Near you* (state), *Spotlight* (editorial + Sponsored, labelled). Search gains "Sponsored" slots in Phase 3 (already designed in A10).
- **Add:** `get_discover_feed()` SQL function (SECURITY INVOKER, RLS decides visibility) that blends recency, popularity from anonymous events, and the signed-in user's **own explicit signals** (follows, saves, request categories). No ML service, no new dependency.
- **Belongs:** `src/app/page.tsx` (stays at `/`; no new route), `src/server/queries/discover.ts`, migration `…_discover_feed.sql`.
- **Connects to:** follows, saves, events model, promotions (placements), Spotlight.
- **Decision D-E3:** personalisation uses only explicit signals (saves/follows/requests) plus browser-local history, consistent with the rule that analytics never store who did an action. Server-side per-user browsing history would be a privacy-policy change.

### 3.2 Purple Stories — *built; upgrade*
- **Upgrade (already planned):** Phase 2 upload tickets, 3×60 s monthly quota, server-side duration check, private quarantine → publish (A1/A2). D1: budget campaigns give way to fixed-price Video Promotion packages in Phase 3.
- **Add:** "Stories from shops you follow" rail; notification to followers on publish (opt-in, rate-limited).
- **Belongs:** unchanged (`/stories`, `/sell/stories`, migration 012 objects).
- **Connects to:** follows, notifications, promotions, Business Studio analytics, Live (a finished live session can later be saved as a story).

### 3.3 Purple Request — *built; upgrade*
- **Upgrade:** write `request_offer` notifications (enum value exists, never used); accepted offer → **booking** (home services) or **checkout** (products/freelance) once step 7 exists — `bookings.request_offer_id` is already in the schema.
- **Add:** sellers opt in to *request alerts* for their categories/states (feeds Purple Match).
- **Belongs:** `/requests/*`, `src/server/*/requests.ts`, migration 020 functions.
- **Connects to:** messaging (unchanged), bookings, checkout, Match, notifications.

### 3.4 Purple Live — *new; last*
- **Exists:** nothing. Closest assets: Stories player, shop-the-video product tags, comment moderation, reports.
- **Add:** live sessions (schedule, go live, product pins, chat, replay → story). Needs a third-party real-time video provider (new dependency + recurring cost + new egress profile) and real-time moderation.
- **Belongs:** `/live`, `/sell/live`, `src/server/services/live/`, `live_sessions`, `live_session_products`, `live_messages`.
- **Connects to:** Stories (replays), cart/checkout, follows (go-live alerts), reports/risk flags, promotions.
- **Recommendation:** run a **costed technical spike** (provider, cost per viewer-hour on Nigerian mobile data, moderation) before committing. Interim: *scheduled Story premieres* reuse Stories at near-zero cost.

### 3.5 Purple Rewards — *schema only*
- **Exists:** `referrals` (with `reward_status`), `profiles.referral_code` (protected), `share_links` (click counts), `reseller_commissions` (3% from platform fee, approved).
- **Add:** an append-only `reward_ledger` (points earned/spent with source), earning rules in `platform_settings`, redemption only as platform credit (e.g. promotion discounts) — **not cash**.
- **Belongs:** `/rewards` (inside My Purple World), `src/server/actions/rewards.ts`, DB functions only (no direct table writes).
- **Connects to:** orders (earn on completed order), referrals, share links, promotions (redeem), risk flags (self-referral/fraud).
- **Depends on:** checkout & escrow + payments ledger. **Decision D-E6:** confirm rewards stay non-cash; take professional advice before any cash-out or reseller payout.

### 3.6 Purple Business Studio — *partly built (it is the Seller hub)*
- **Exists:** `/sell` hub, seller progress, listings, stories + analytics, promote, orders (read-only), profile, pro page, verification; saves counts per listing.
- **Upgrade:** rename the Seller hub to **Business Studio** in navigation only. **Keep `/sell/*` URLs** so no link breaks. Add: *Insights* (listing views, saves, enquiries, sources), *Promotions* (Phase 3), *Deals*, *Bookings calendar*, *Followers*, *Reviews inbox*.
- **Belongs:** `/sell/*`, `sellerNav()` in `src/components/nav/nav-config.ts`, `src/server/queries/studio.ts`.
- **Connects to:** every seller-side module; the events model; promotions; orders/payouts.

### 3.7 Purple Professional — *step 1 built*
- **Exists:** `/pro/[username]`, two modes, `pro_entries`, skills/languages, Free/Premium flag (manual), private by default.
- **Upgrade (existing plan):** step 2 portfolio projects; step 3 Creative Space builder (gallery/video); Premium via Phase 2/3 billing.
- **Add:** tracked external-link redirect (for Professional Profile Boost reporting, A10); "Hire" CTA → enquiry or booking.
- **Connects to:** search (`search_sellers` already matches headline), Match, bookings, reviews, promotions.

### 3.8 Purple Deals — *new*
- **Add:** `deals` (listing, deal price, starts/ends, quantity cap, status). **Rules in the DB:** deal price below the listing's price for the previous N days (configurable) to prevent fake discounts; max duration; seller 2FA via `can_post()`; editing a live deal sends it to review like listings.
- **Belongs:** `/deals` (Discover surface), `/sell/deals` (Studio), `search_listings` gains a deal filter.
- **Connects to:** listings, price alerts (a deal triggers saved-item alerts), promotions (Deals placement), checkout (deal price locked at checkout).
- **Depends on:** checkout & escrow (a deal you can't buy is just a banner); price history (record price changes from now on — cheap, can start early).

### 3.9 Purple Community — *new; after admin & moderation*
- **Add:** topic spaces per section/category, posts and replies, maker Q&A. Reuse `contact_problem()` blocking, reports, 3-reporter auto-hide, risk flags, rate limits.
- **Belongs:** `/community`, `community_posts`, `community_replies`.
- **Connects to:** profiles, follows, Spotlight (feature a post), reports/admin.
- **Depends on:** backend step 8 (admin screens). User-generated discussion is the highest moderation load of any module.

### 3.10 Purple Match — *new; built on Requests + search*
- **Add:** `match_sellers_for_request(request_id)` scoring category, state/service areas, skills, verification, rating, response rate, taking-orders switch. Uses: (a) "Suggested pros" on a buyer's request, (b) request alerts to matching sellers, (c) a short "Find me a pro" questionnaire that creates a request.
- **Belongs:** inside `/requests` (no separate app), `src/server/queries/match.ts`, one migration.
- **Connects to:** Requests, Professional, service areas, reviews (once live), notifications.
- **Rule:** buyers stay anonymous until they accept an offer (existing Request rule); sellers still can't contact buyers first.

### 3.11 Purple Business Spotlight — *partly built*
- **Exists:** `content_features` (Meet the Maker log), `featured_until`, `featured_purchases` (unused), `story_campaigns`, and the A10 *Store Spotlight* promotion type (designed, Phase 3).
- **Two lanes, one placement system:** **Editorial** Spotlight (admin-picked, free, e.g. Maker of the Week — already in your marketing plan) and **Paid** Store Spotlight (Phase 3 package). Both render in the same homepage/shop placements; paid ones are labelled **Sponsored**.
- **Belongs:** `/spotlight` (archive page), homepage section, `/admin/spotlight` (step 8), the Phase 3 `promotions` tables.
- **Connects to:** promotions, Discover, Stories, Community.
- **Note:** distinct from Phase 4 *Purple Business Campaigns* (self-serve ad creatives). Spotlight is placement of existing shops/pages.

### 3.12 My Purple World — *partly built (it is the buyer side of `/account`)*
- **Exists:** `/account`, `/saved`, `/cart`, `/messages`, `/requests/mine`, privacy & security pages, recently viewed.
- **Upgrade:** `/account` becomes the **My Purple World** hub: Following, Saved (with alert toggles), My requests, Orders & bookings (step 7), Reviews to write, Rewards, Notifications, Settings. Keep existing URLs; nav label "Me" stays on phones.
- **Belongs:** `/account/*`, `src/server/queries/me.ts`.
- **Connects to:** every buyer-side feature.

## 4. Supporting features

| Feature | Today [Fact] | Upgrade / add [Proposal] | Depends on |
|---|---|---|---|
| Shop following | `follows` table + toggle on shop and story viewer; `seller_follow_info()` | Follower count on shop/pro, *Following* list in My Purple World, followers list (counts only, never names, to match the save-privacy rule — **decision D-E4**), "new from shops you follow" | Notifications |
| Wishlists | `saves` (single list, 500 cap), `/saved` | Keep one list for v1; add per-item **alert toggles** (price drop, back in stock). Named collections later only if asked for | — |
| Price alerts | None | `save_alerts` opt-in flag + trigger on `listings.price_kobo` decrease → in-app notification; daily cap per user. Seller never sees who | Notifications, price history |
| Restock alerts | `listings.stock` exists, nothing reads it for alerts | Same trigger on `stock` 0 → >0 | Notifications |
| Bookings | `bookings` table, statuses, `get_booking_address()` privacy release | RPCs `request_booking/accept/decline/start/complete`, buyer + pro screens, calendar using `working_hours` | Checkout & escrow (pay on accept) |
| Customer reviews | `reviews` + `validate_review` (completed order/booking only) + owner reply + rating refresh | Review prompt after completion, review list on shop/pro/listing, Studio reply inbox, admin hide (step 8) | Completed orders/bookings |
| Seller analytics | Stories analytics + campaign analytics; listing save counts | Unified Studio *Insights*: listing views, saves, carts, enquiries by source, followers, (later) orders | Events model (write `listing_events`) |
| Personalised recommendations | Recently viewed (local only) | Discover feed function (§3.1), "Similar items" on listing pages by category/tags/price band | Events model, follows, saves |

## 5. How modules connect to the core

| Core system | Rule for every new module |
|---|---|
| **User accounts** | One identity: `profiles`. No module creates its own user table. Seller-side writes require `can_post()` (seller + 2FA + active account). Suspended/banned accounts are hidden everywhere through the existing `account_ok()`. |
| **Messaging** | All buyer↔seller contact goes through `start_conversation`/`send_message`, so the contact-details blocker and user blocks always apply. Add a `source` (+ optional `promotion_id`, `deal_id`, `request_id`) to `start_conversation` — already planned for Phase 3 enquiry tracking. Sellers still never message first. |
| **Payments** | One money path: Paystack initialise on the server → webhook is the only activator → idempotent `confirm_payment()` → `payments` ledger (A4/O3). Orders, bookings, Deals, promotions, Premium and any Live tips use it. No module talks to Paystack directly. Money stays in kobo. |
| **Seller profiles** | Shop page and pro page are views of one `profiles` row. New seller-facing data (deals, live sessions, spotlight entries) hangs off `profiles.id` and is shown in those two pages. |
| **Promotions** | One promotion system (A10 registry). New target types are rows + an eligibility function: *Deal Boost*, *Live Session Boost*, editorial *Spotlight*. Every paid placement is labelled **Sponsored**; organic results are never removed. |
| **Safety** | Every text field passes `contact_problem()`; every new public object is reportable; new risk flag types where needed (deal price abuse, referral fraud). |
| **Privacy** | Export and account deletion are extended for every new table in the same migration that creates it (the existing pattern). Analytics stay anonymous. |

## 6. Prioritisation

Scores 1–5 (5 = best for value/UX; 5 = *lowest* complexity/cost). Dependencies are hard blockers.

| Item | Biz value | UX | Complexity (5 = simple) | Cost (5 = cheap) | Hard dependencies | Tier |
|---|---|---|---|---|---|---|
| Phase 1b remainder (W7–W12) | 5 | 3 | 3 | 5 | — | **0 — now** |
| Notification centre (in-app) | 4 | 5 | 4 | 5 | 1b | 1 |
| Events model (`listing_events` writing) | 4 | 2 | 4 | 5 | 1b | 1 |
| Phase 2 Founding plan + video limits | 5 | 4 | 3 | 4 | 1b | 1 |
| Checkout & escrow (step 7) | 5 | 5 | 2 | 4 | 1b, O3, Paystack account | 1 |
| My Purple World hub + Following | 3 | 5 | 5 | 5 | Notifications | 2 |
| Business Studio + Insights | 4 | 4 | 4 | 5 | Events model | 2 |
| Price & restock alerts | 3 | 5 | 4 | 5 | Notifications | 2 |
| Discover v1 (feed, similar items) | 4 | 5 | 3 | 5 | Events, follows | 2 |
| Admin screens (step 8) | 4 | 2 | 3 | 5 | 1b | 2 |
| Featured Promotions + Business Spotlight (Phase 3) | 5 | 3 | 2 | 4 | Checkout, admin, events | 3 |
| Bookings | 4 | 4 | 3 | 5 | Checkout | 3 |
| Customer reviews | 5 | 4 | 4 | 5 | Completed orders/bookings | 3 |
| Purple Match v1 | 4 | 4 | 3 | 5 | Requests, notifications | 3 |
| Professional steps 2–3 | 3 | 4 | 3 | 4 | Phase 2 storage rules | 3 |
| Purple Deals | 4 | 4 | 3 | 5 | Checkout, price history, promotions | 4 |
| Purple Business Campaigns (Phase 4) | 4 | 2 | 2 | 4 | Phase 3 | 4 |
| Purple Rewards | 3 | 3 | 3 | 4 | Checkout, payments ledger, D-E6 | 4 |
| Purple Community | 3 | 3 | 2 | 4 | Admin & moderation | 5 |
| Purple Live | 3 | 4 | 1 | 1 | Checkout, spike, new provider | 5 (spike first) |

## 7. Recommended implementation order

1. **Phase 1b (in progress):** W7 test harness → W8 CI/CD → W9–W11 → W12 report. Unchanged. Nothing below starts before 1b is accepted.
2. **Phase 2 + foundations:** Founding Free Plan and video limits (as planned), `platform_settings`, notification centre, events model, price-history recording.
3. **Checkout & escrow** (backend step 7) on the O3 architecture.
4. **Buyer & seller hubs:** My Purple World, Following, Business Studio rename + Insights, price/restock alerts, Discover v1, admin screens (step 8).
5. **Phase 3:** Featured Promotions with Business Spotlight (paid + editorial).
6. **Transactions on top of checkout:** Bookings, Reviews, Purple Match v1, Professional steps 2–3.
7. **Phase 4 + Deals + Rewards.**
8. **Community**, then **Live** (only after a spike is approved).

Every step keeps the existing gate: plan → owner approval → staging → tests → production with separate approval (ADR-001).

## 8. Cleanup found during inspection (not done; needs approval)

| # | Finding [Fact] | Proposal |
|---|---|---|
| X1 | `src/app/actions/*.ts` (12 files) are older copies of `src/server/actions/*.ts`; nothing imports them. | Delete in one small PR after W7 tests exist. Prevents someone "fixing" the wrong copy. |
| X2 | `src/lib/{auth,catalog,messages,requests,search,stories,verification,seller}.ts` duplicate `src/server/*`; only import each other. | Same PR as X1. |
| X3 | README describes stories as "90 seconds / 10 a day" and lists the old roadmap (steps 6–9) separately from Phases 2–5. | Update README when Phase 2 ships; `ROADMAP.md` becomes the single roadmap. |
| X4 | Unused enums/tables (`featured_purchases`, `content_type`) overlap the planned promotions model. | Replace/retire inside Phase 3 as already proposed (0 rows). |

## 9. Dependencies (packages and services)

No new npm packages are needed for anything up to and including Tier 4 except what Phase 3 already approved in principle (Paystack is called over HTTPS from Edge Functions; no SDK required). New external services are proposed only where unavoidable:

| Need | When | Option | Decision |
|---|---|---|---|
| Transactional email (alerts, booking/order receipts) | Tier 1–2 | Resend / Postmark / Supabase SMTP | D-E2 |
| Web push (optional; PWA `sw.js` exists) | Tier 2+ | Native Web Push via an Edge Function | D-E2 |
| Live video | Tier 5 | Provider chosen in the spike | D-E8 |
| Test tooling | 1b W7 | pgTAP, Vitest, Playwright (already planned) | Approved in 1b |

## 10. Decisions needed from you

| # | Decision | Recommendation |
|---|---|---|
| D-E1 | Adopt the unified roadmap (`ROADMAP.md`) as the single roadmap, merging README steps 6–9 with Phases 2–5 | Approve |
| D-E2 | Notification delivery channels | In-app first; email for orders/bookings at step 7; web push later |
| D-E3 | Personalisation data | Explicit signals + browser-local history only; no server-side browsing history |
| D-E4 | Can sellers see *who* follows them? | No — counts only, consistent with saves |
| D-E5 | Keep `/sell` and `/account` URLs, rename only labels (Business Studio, My Purple World) | Approve |
| D-E6 | Rewards are non-cash platform credit only | Approve; take advice before any cash value |
| D-E7 | Bookings: allow request/accept before payments exist, or wait for escrow | Wait for escrow (avoids off-platform payment pressure) |
| D-E8 | Purple Live: approve a costed spike (no build) at Tier 5 | Approve spike only, later |
| D-E9 | Cleanup X1–X2 after W7 | Approve |

## 11. Next step

Review this plan and answer D-E1–D-E9. Approval of this plan authorises **no implementation**: Phase 1b continues with W7 on your go-ahead, and each module later gets its own scoped plan and approval.
