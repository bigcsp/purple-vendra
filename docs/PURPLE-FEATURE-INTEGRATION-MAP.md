# Purple Ecosystem — Feature Integration Map

**Status:** **Proposed — awaiting owner review.** Read-only inspection; no changes made.
**Evidence base:** repository `phase-1b-foundation` @ `c72978a` and `docs/expansion-integration-plan` @ `ecc9c31` (26 migrations; `src/app`, `src/server`); production schema manifest `docs/schema/production-manifest-2026-11-16.tsv` (470 objects, matched by the clean staging rebuild on 19 Nov). Live production data was **not** queried for this task.
Relationship: [`FEATURE-MAP.md`](FEATURE-MAP.md) records *where each module lives*. This document classifies *every capability in the ecosystem brief* by division.

**Classification** (brief §12):
- **✅ Implemented**: works end-to-end in the app today.
- **◐ Partial**: some of it is built (often schema without screens, or a screen without data).
- **⬆ Needs improvement**: built, but has a known defect or doesn't meet the brief.
- **➕ New**: proposed; nothing exists.
- **⏸ Future**: deferred to Phase 5 or later.

A feature is only marked ✅ where code or schema evidence is cited.

---

## 1. Shared platform

| Capability | Class | Evidence [Fact] | Next step / stage |
|---|---|---|---|
| One account and identity | ✅ | `profiles`; shop and pro pages are views of one row | Keep |
| Roles and seller gate (2FA) | ✅ | `user_role`, `become_seller()`, `can_post()` (aal2) | Keep |
| Multiple divisions per business | ◐ | Type is per listing, so one seller can list a product and a service; there's no stored business type | Derived division (divisions doc §3) |
| Messaging | ✅ | `start_conversation`, `send_message`, contact-details blocker, `user_blocks` | Add enquiry `source` (S2) |
| Notifications | ◐ | `notifications` table + enum; **never written**; no preferences | Notification centre (S2) + preferences (ECO-D7) |
| Reviews | ◐ | `reviews`, `validate_review` (completed job only), owner reply, rating trigger; no screens; no completed jobs possible yet | S6 after checkout |
| Search and discovery | ◐ | `search_listings`, `search_sellers` across all categories, suggestions, category pages | Division badges and filters (S4/S6) |
| Promotions | ◐ | `featured_until`, `story_campaigns` (budget), `featured_purchases` (unused); A10 registry designed | Phase 3 (S5) |
| Analytics foundation | ◐ | `story_events` live; `listing_events` never written | Events model (S2) |
| Payments | ➕ | `checkouts`/`orders`/`payouts` schema; no provider; O3 design approved | S3 |
| Trust, safety, moderation | ⬆ | Reports, auto-hide, `risk_flags`, `security_events`, account status; **no admin screens** (SQL editor) | Admin screens (S4) |
| Privacy: export and deletion | ✅ | Migration 011 (`export_my_data`, deletion queue, retention cron) | Extend per new table |

## 2. Purple Shop: products and commerce

| Capability (brief §2A) | Class | Evidence | Next step / stage |
|---|---|---|---|
| Storefront | ✅ | `/shop/[username]`, `/sell/profile` | Keep |
| Product catalogue | ✅ | `listings` type `product`, categories, approval flow | Keep |
| Product images | ✅ | `listing_images`, `listing-images` bucket | Keep |
| Product videos and stories | ✅ / ⬆ | Purple Stories + shop-the-video; **quota bypass R2** fixed in Phase 2 | Phase 2 (S2) |
| Inventory | ◐ | `listings.stock` only; no reservation or decrement without checkout | S3 |
| Orders | ◐ | Schema; `/sell/orders` read-only | S3 |
| Delivery information | ◐ | `delivery_mode` enum; no delivery tracking or fees | S3 |
| Pricing | ✅ | `price_kobo`, "from ₦X" flag | Keep |
| Bundles | ➕ | — | Coach suggestion first; bundle listings later (S7) |
| Promotions and deals | ◐ / ➕ | Promotions as above; Deals new (ADR-003) | S5 / S7 |
| Product reviews | ◐ | `reviews` schema | S6 |
| Repeat-purchase tools | ➕ | — | Customer Connection (S6+) |
| Sales and product insights | ◐ | Save counts only | Insights (S4) |
| Wider product categories (electronics, food, beauty, groceries, furniture) | ➕ | Only creative categories exist | ECO-D3 |

## 3. Purple Handy Pro: hands-on and local services

| Capability (brief §2B) | Class | Evidence | Next step / stage |
|---|---|---|---|
| Professional profile | ✅ | Shop page fields `business_name`, `headline`, `years_experience`, `is_available`; `/pro` | Keep |
| Service catalogue | ✅ | `listings` type `service` in `home-services`; fixed price or `quote_on_request` | Sub-categories (S6) |
| Service areas and location discovery | ◐ | `service_areas` editable in `/sell/profile`, shown on shop page; **search doesn't filter by area** | Area filter (S4/S6) |
| Availability | ◐ | `working_hours`, `is_available` toggle | Booking calendar (S6) |
| Appointment requests and bookings | ◐ | `bookings` table, `booking_status`, `get_booking_address()` (address released after accept); **no RPCs or screens** | S6 (needs S3; D-E7) |
| Customer problem description | ◐ | `bookings.job_details` (text); Requests are text-only by owner decision | Photos/videos: ECO-D10 (moderation and storage cost) |
| Quotations | ✅ / ◐ | Requests → offers (max 10) → accept → private chat; quote not linked to a booking or payment | S6 |
| Job status and completion records | ◐ | `booking_status` values; nothing writes them | S6 |
| Before-and-after portfolio | ➕ | `pro_entries` has experience/education/certification/achievement only | Pro step 2 (S6) |
| Verification | ✅ | ID required before a home-services listing goes live (trigger) | Trade certificates (later) |
| Reviews | ◐ | As shared | S6 |
| Repeat and maintenance reminders | ➕ | — | Opt-in reminders (S6+, ECO-D7) |

## 4. Purple Professionals: freelance, tech and creative services

| Capability (brief §2C) | Class | Evidence | Next step / stage |
|---|---|---|---|
| Professional profile | ✅ | `/pro/[username]`, `pro_mode`, skills, languages, `pro_entries`, private by default | Keep |
| Portfolio | ◐ | Entries + external links; no project gallery | Pro step 2–3 (S6) |
| Skills, experience, descriptions | ✅ | `pro_profiles` fields | Keep |
| Service packages and indicative pricing | ◐ | Listings (`service`/`talent`) with "from ₦X"; no tiered packages | ➕ Package tiers (S6) |
| Consultations | ➕ | — | Bookable "consultation" listing using bookings (S6) |
| Project requests, proposals, quotations | ✅ / ◐ | Purple Requests + offers serve as proposals; no milestones | Request → checkout link (S6) |
| Client communication | ✅ | Messaging | Keep |
| Project status | ➕ | — | Order status for service orders (S3/S6) |
| Testimonials and reviews | ◐ | `reviews` (verified only, owner decision) | S6. Off-platform testimonials: not allowed as reviews; could be labelled "Client quote, unverified" (ECO-D11) |
| Client retention | ➕ | — | Customer Connection |

## 5. Onboarding

| Capability (brief §4) | Class | Evidence | Next step |
|---|---|---|---|
| Ask what the business offers | ◐ | Sign-up intent shop/sell/both; listing form asks type per listing | Studio first-run question (ECO-D6, S6) |
| Fields adapt to business type | ◐ | Listing form switches on type; seller-progress checklist is generic | Division checklist (S6) |
| Multiple divisions | ◐ | Per-listing type | `seller_divisions` preference (Option A+) |

## 6. Purple Marketing Intelligence

| Capability (brief §5) | Class | Evidence | Next step / stage |
|---|---|---|---|
| Insights: views, enquiries, orders, bookings, projects | ◐ | Story analytics only | Events (S2) → Insights (S4) |
| Insights: conversion and response time | ➕ | Derivable from messages; not computed | S4 |
| Insights: best products and services | ➕ | — | S4 |
| Insights: new vs returning customers | ➕ | Needs completed orders | S6 |
| Insights: promotion performance | ◐ | `get_campaign_analytics()` for stories | Phase 3 (S5) |
| Anonymous demand insights | ◐ | `search_queries` logged; no seller view (approved v1 idea "weekly demand insights") | S4 |
| Marketing Coach (rules) | ➕ | — | S4/S5 |
| Category-specific Growth Assistants | ➕ | — | S5/S6 |
| Customer Connection Assistant | ➕ | Blocked by the missing consent model; must respect "no seller-first contact" | S6+ |
| Campaign Assistant | ◐ | Story campaigns; Phase 3/4 designs | S5/S7 |
| AI explanations and drafting | ⏸ | — | S7+ after ECO-D9 |
| Experimentation | ⏸ | — | S8+ |

## 7. Marketing principles (brief §6) vs existing mechanisms

| Principle | Supported by today [Fact] | Gap |
|---|---|---|
| Scarcity (genuine) | `stock`, request 14-day expiry | No deal end dates yet |
| Social proof | Verified badge, verified-only reviews, follower and save counts | Reviews need completed jobs |
| Personalisation | Recently viewed (browser-local) | Discover feed (S4; D-E3 privacy rule) |
| Storytelling | Purple Stories, Meet the Maker (`content_features`) | — |
| Bundling, cross-sell | — | New |
| Retention | Follows | Notifications and consent |
| Experimentation | — | New |

## 8. Unified discovery

| Capability (brief §8) | Class | Evidence | Next step |
|---|---|---|---|
| One search across products, services, people | ◐ | `search_listings` (all types and categories) + `search_sellers` | Keep; no replacement |
| Division labels on results | ➕ | — | S4 (derived division) |
| Filters: location, price, availability, category, verified | ◐ | Category and price in search; verified badge shown; **no area or availability filter** | S4/S6 |
| Cross-division intent ("bedroom makeover") | ⏸ | Synonyms table exists (`search_synonyms`) | Curated intent synonyms first (cheap), AI later |

## 9. ADR-003 modules re-homed under the divisions

| ADR-003 module | Home in the ecosystem |
|---|---|
| Purple Discover | Unified discovery (§8) |
| Purple Business Studio | Seller home for all divisions; MI lives here |
| My Purple World | Customer home across divisions |
| Purple Stories | Shared (strongest for Shop and creative Professionals) |
| Purple Request + Purple Match | Shared demand engine; core of Handy Pro and Professionals |
| Purple Professional | Professionals (and Handy Pro profiles) |
| Purple Business Spotlight | Campaign Assistant placements |
| Purple Deals | Shop (Campaign Assistant) |
| Purple Rewards, Community, Live | Ecosystem-wide, **deferred behind core journeys and measurement** (ROADMAP v0.2) |

## 10. Duplication, constraints, security and cost risks found

| # | Finding | Impact on this direction |
|---|---|---|
| F1 | `sections` (Creative/Freelance/Home) cut across divisions | Don't rename; derive divisions (divisions doc §2–3) |
| F2 | "Purple Shop" = whole-site brand today | Naming decision ECO-D1 |
| F3 | `listing_events` and `notifications` never written | MI and Customer Connection blocked until S2 |
| F4 | No consent or notification-preference model | Blocks reminders and follow-ups (ECO-D7) |
| F5 | Sellers-can't-contact-first rule | Customer Connection must be platform-sent and opt-in |
| F6 | Dead duplicate code `src/app/actions/*`, `src/lib/*` (ADR-003 X1–X2) | Remove before division code lands, so nobody edits the wrong copy |
| F7 | Storage and egress cost model (A6) is video-only | Photos and videos on Handy Pro problem descriptions (ECO-D10) would add storage and moderation cost; re-run `cost-model.py` before allowing them |
| F8 | AI calls are a new recurring cost | On-demand only, capped, cached (MI doc §7) |
| F9 | Regulated categories (food, beauty, electronics) | Legal, moderation and claim-checking load (ECO-D3) |
| F10 | No admin screens | Every new division and MI rule needs admin tooling (S4) |
| F11 | Repository is still public (O15 approved to make private) | Strategy docs are now in the repo; recommend completing O15 |
