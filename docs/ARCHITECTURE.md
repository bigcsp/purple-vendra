# Purple Shop — Architecture

**Status:** current architecture [Fact] + target module architecture [Proposal, awaiting approval].
Related: [`EXPANSION-INTEGRATION-PLAN.md`](EXPANSION-INTEGRATION-PLAN.md) · [`FEATURE-MAP.md`](FEATURE-MAP.md) · [`ROADMAP.md`](ROADMAP.md) · [`PHASE-1B-PLAN.md`](PHASE-1B-PLAN.md)

## 1. Principles (apply to every module)

1. **Extend, never fork.** One app, one database, one user system (`profiles`). Modules are folders and tables inside the existing three parts, not new services.
2. **The database is the final lock.** Rules that protect money, privacy or safety live in Postgres (RLS, triggers, `SECURITY DEFINER` RPCs with internal checks). The website and backend call them.
3. **Writes go through functions** for anything with business rules (the Requests and Messaging pattern). Tables stay read-only to the API where possible.
4. **Seller writes need `can_post()`** (seller role + 2FA `aal2` + active account).
5. **Anonymous analytics.** Event tables never store who acted. Sellers see counts, never names, for saves, alerts and follows.
6. **One money path** (Paystack → webhook → `confirm_payment()` → `payments` ledger, in kobo). Decision O3.
7. **One promotion system** (A10 registry). Every paid placement says **Sponsored**.
8. **Everything configurable is in `platform_settings`** (Phase 2), not hard-coded in triggers.
9. **Privacy by migration:** a migration that adds a personal-data table also extends export, deletion and retention.
10. **Staging first:** no production change without the ADR-001 gate.

## 2. Current system [Fact]

```
                Buyers / sellers (mobile-first PWA)
                              │
                ┌─────────────▼──────────────┐
                │  Vercel (lhr1) — Next.js 16 │
                │  src/app        pages/routes│
                │  src/components UI          │
                │  src/server     backend     │  server-only, user's own session
                │   ├ auth/ queries/ actions/ │  (no service-role key)
                │   ├ api/  (→ /api/* routes) │
                │   └ services/ (empty: payments next)
                └─────────────┬──────────────┘
                              │ supabase-js (RLS applies)
                ┌─────────────▼──────────────┐
                │ Supabase (eu-west-2)        │
                │  Postgres 17: ~50 tables,   │
                │   RLS everywhere, RPCs,     │
                │   triggers, pg_cron jobs    │
                │  Auth + TOTP 2FA            │
                │  Storage: listing-images,   │
                │   id-documents, story-media │
                │  Edge Fn: storage-cleanup   │
                └─────────────────────────────┘
  Staging: separate free Supabase project (Phase 1b W4/W5/W6)
```

Scheduled jobs: `story-campaigns-complete` (hourly), `requests-expire` (hourly), `privacy-retention` (nightly), `storage-cleanup` (nightly).

## 3. Domain map — existing domains and where new modules attach

| Domain | Existing tables / functions | New modules & features attach here |
|---|---|---|
| **Identity** | `profiles`, `seller_verifications`, `seller_register`, `security_events`, `user_blocks` | My Purple World, Professional, Rewards (referral code) |
| **Catalogue** | `sections`, `categories`, `listings`, `listing_images`, `service_areas`, `working_hours` | Deals, price history, restock |
| **Discovery** | `search_*` functions, `search_synonyms`, `search_queries`, `popular_searches` | Discover feed, Match scoring, Spotlight placements |
| **Content** | `story_*` tables, `content_features` | Stories upgrades, Live, Community, editorial Spotlight |
| **Engagement** | `saves`, `follows`, `cart_items`, `notifications` (unused), `share_links` (unused) | Following, alerts, notification centre, Rewards |
| **Demand** | `buyer_requests`, `request_offers` | Request upgrades, Match |
| **Conversation** | `conversations`, `messages` | Source tagging for every module's enquiries |
| **Commerce** | `checkouts`, `orders`, `order_items`, `payouts`, `disputes`, `bookings`, `reviews`, `reseller_commissions` (all unused or read-only) | Checkout & escrow, Bookings, Reviews, Deals purchase, Rewards earning |
| **Promotion** | `story_campaigns`, `featured_purchases` (unused), `listings.featured_until` | Phase 3 `promotion_*` + `promotions`, Business Spotlight, Deal/Live boosts |
| **Analytics** | `story_events`, `story_cart_attributions`, `listing_events` (unused) | Unified events model, Studio Insights, Discover ranking |
| **Trust & safety** | `reports`, `risk_flags`, `contact_problem()`, privacy export/deletion | Applied to every new module |

## 4. Target code layout [Proposal]

No new top-level folders. New files follow the existing pattern (`queries/` read, `actions/` write, `services/` secrets):

```
src/app/
  page.tsx                 Purple Discover (homepage stays at /)
  deals/                   Purple Deals (new)
  spotlight/               Business Spotlight archive (new)
  community/               Purple Community (new, late)
  live/                    Purple Live (new, last)
  requests/                Purple Request + Match (existing; Match lives inside)
  stories/                 Purple Stories (existing)
  pro/[username]/          Purple Professional (existing)
  account/                 My Purple World (existing URL, new hub sections:
    following/ alerts/ orders/ bookings/ reviews/ rewards/ notifications/)
  sell/                    Business Studio (existing URL, new sections:
    insights/ promotions/ deals/ bookings/ reviews/ followers/ live/)
  admin/                   Step 8 (planned): moderation, packages, spotlight, payments
src/server/
  queries/  discover.ts match.ts studio.ts me.ts deals.ts notifications.ts …
  actions/  follows.ts alerts.ts deals.ts bookings.ts reviews.ts rewards.ts …
  services/ payments/ (Phase 3/step 7)  email/  live/ (after spike)
supabase/
  migrations/  one migration per module step, timestamp-named (C1 Option A layout)
  functions/   paystack-webhook, (later) notify-email, verify-media …
  tests/       pgTAP per module (W7 harness)
```

## 5. Cross-cutting foundations to build once

| Foundation | Design | Used by |
|---|---|---|
| **Notification centre** | Use existing `notifications`; add `notification_type` values (`follow_new_post`, `price_drop`, `back_in_stock`, `booking_update`, `deal_live`, `request_match`, `reward_update`); `notification_prefs` per user; insert only via `private.notify()` with per-type rate caps; bell + `/account/notifications`; email via an Edge Function later | All modules |
| **Events model** | Generalise the `story_events` pattern: anonymous `(subject_type, subject_id, event, placement, source_id, at)`; start writing listing views; daily rollup table for fast Insights | Studio Insights, Discover, Spotlight/Promotion reporting, Match |
| **Price history** | `listing_price_history` written by trigger on price change | Deals fake-discount rule, price alerts |
| **Platform settings** | Phase 2 `platform_settings` row (already planned) holds quotas, caps, deal rules, reward rates | All modules |
| **Payments** | O3/A4: Paystack via Edge Functions, `payments`, `payment_events`, `confirm_payment()` | Checkout, bookings, promotions, Premium, Deals, Rewards redemption, Live tips |
| **Promotion registry** | A10 `promotion_target_types` + `promotions` + `promotion_events` | Spotlight, Deal Boost, Live Boost, Video Promotion |

## 6. Module dependency graph

```
Phase 1b ──► Phase 2 (settings, quotas) ──┬──► Notification centre ──► Following, Alerts, My Purple World
                                         ├──► Events model ──► Studio Insights, Discover v1
                                         └──► Checkout & escrow ──┬──► Bookings ──► Reviews
                                                                  ├──► Phase 3 Promotions ──► Business Spotlight, Phase 4
                                                                  ├──► Deals (+ price history, promotions)
                                                                  ├──► Rewards (+ payments ledger)
                                                                  └──► Live (+ spike, provider)
 Requests ──► Match (+ notifications, later reviews)
 Admin screens (step 8) ──► Community, Spotlight editorial, Deals review
```

## 7. Dependencies

**Runtime (unchanged):** next 16.4.5, react 19.3, @supabase/ssr, @supabase/supabase-js, @ffmpeg/ffmpeg + core (browser transcode), lucide-react, geist, bricolage font, server-only, Tailwind v4.
**Planned, already approved in principle:** pgTAP, Vitest, Playwright (W7); Deno check in CI (W8); Paystack over HTTPS from Edge Functions (no SDK).
**Proposed, each needs its own approval:** an email provider (D-E2); a live-video provider after the spike (D-E8).
**Rejected for now:** recommendation/ML services, search engines (Postgres search already covers it), real-time chat SDKs (messaging works on Postgres), separate CMS for Community/Spotlight.
