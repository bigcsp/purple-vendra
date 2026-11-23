# Purple Shop — Feature Map

**Status keys:** ✅ live · ◐ partly built · 🗄 schema only (no screens) · ➕ new · ⏸ deferred
Source of truth for *where each feature lives*. Update it in the same PR that changes a feature.
Plan: [`EXPANSION-INTEGRATION-PLAN.md`](EXPANSION-INTEGRATION-PLAN.md) · Order: [`ROADMAP.md`](ROADMAP.md)

## Modules

| Module | Status | Routes (existing → planned) | Backend | Database | Roadmap stage |
|---|---|---|---|---|---|
| Purple Discover | ◐ | `/`, `/search`, `/c/[slug]` → homepage sections | `queries/catalog.ts`, `queries/search.ts` → `queries/discover.ts` | `search_*` (014, 018) → `get_discover_feed()` | S4 |
| Purple Stories | ✅ | `/stories`, `/shop/[u]`, `/sell/stories/*` | `queries/stories.ts`, `actions/stories.ts`, `actions/campaigns.ts` | 012 story tables | Upgrades S2 (quota), S5 (promotion packages) |
| Purple Request | ✅ | `/requests`, `/requests/new`, `/requests/[id]`, `/requests/mine` | `queries/requests.ts`, `actions/requests.ts` | 020 functions | Notifications S2; booking/checkout link S6 |
| Purple Live | ➕ ⏸ | → `/live`, `/sell/live` | → `services/live/` | → `live_sessions`, `live_session_products`, `live_messages` | S8 (spike first) |
| Purple Rewards | 🗄 | → `/account/rewards` | → `actions/rewards.ts` | `referrals`, `share_links`, `reseller_commissions` → `reward_ledger` | S7 |
| Purple Business Studio | ◐ (= Seller hub) | `/sell/*` → + `insights`, `promotions`, `deals`, `bookings`, `reviews`, `followers` | `queries/seller-progress.ts` → `queries/studio.ts` | events model | S4 onward |
| Purple Professional | ◐ (step 1) | `/pro/[u]`, `/sell/pro` | `queries/pro.ts`, `actions/pro.ts` | 022 `pro_entries`, plan flags | Steps 2–3 at S6 |
| Purple Deals | ➕ | → `/deals`, `/sell/deals` | → `queries/deals.ts`, `actions/deals.ts` | → `deals`, `listing_price_history` | S7 (history recorded from S2) |
| Purple Community | ➕ ⏸ | → `/community` | → `queries/community.ts` | → `community_posts`, `community_replies` | S8 |
| Purple Match | ➕ | inside `/requests` | → `queries/match.ts` | → `match_sellers_for_request()`, seller request-alert prefs | S6 |
| Purple Business Spotlight | ◐ | → `/spotlight`, homepage section, `/admin/spotlight` | → Phase 3 promotions service | `content_features`, `featured_until` → `promotions` (A10) | S5 |
| My Purple World | ◐ (= `/account`) | `/account`, `/saved`, `/cart`, `/messages` → + `following`, `alerts`, `orders`, `bookings`, `reviews`, `rewards`, `notifications` | → `queries/me.ts` | existing + notifications | S4 |

## Supporting features

| Feature | Status | Where today [Fact] | Planned home |
|---|---|---|---|
| Shop following | ✅ basic | `follows`; toggle in `actions/shop.ts` and story viewer; `seller_follow_info()` | Counts on shop/pro, Following list (My Purple World), Followers count (Studio) |
| Wishlist (Saved) | ✅ | `saves`, `/saved`, `api/saves`, `my_listing_save_counts()` | + per-item alert toggles |
| Price alerts | ➕ | — | `save_alerts`, price trigger, notifications |
| Restock alerts | ➕ | `listings.stock` exists | Stock trigger, notifications |
| Bookings | 🗄 | `bookings`, `booking_status`, `get_booking_address()` | Booking RPCs + screens after checkout |
| Customer reviews | 🗄 | `reviews`, `validate_review`, `protect_review`, `refresh_seller_rating` | Prompts + display after completed orders |
| Seller analytics | ◐ | Stories analytics, campaign analytics, save counts | Studio Insights on events model |
| Personalised recommendations | ◐ | Recently viewed (browser-local) | Discover feed, "similar items" |
| Notifications | 🗄 | `notifications` table + enum, never written | Notification centre (S2) |
| Referrals / share links | 🗄 | `referrals`, `profiles.referral_code`, `share_links` | WhatsApp share kit + Rewards |
| Checkout & escrow | 🗄 | `checkouts`, `orders`, `payouts`, `disputes`; `/cart`; `/sell/orders` read-only | S3 |
| Admin screens | ➕ | SQL editor + `admin_*` functions | `/admin` (S4) |

## Navigation (labels only; URLs unchanged)

| Today | Proposed label |
|---|---|
| Home | Discover (tab may stay "Home" on phones) |
| Requests | Requests (Match inside) |
| Stories | Stories (Live tab added at S8 if approved) |
| Seller hub | Business Studio |
| My account / Me | My Purple World / Me |
