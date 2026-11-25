# Purple Ecosystem — Product Direction

**Source brief:** *Purple Ecosystem — Product Direction & Smart Marketing Project Guide* (owner, 24 Nov 2026). Original kept verbatim at [`briefs/2026-11-24-purple-ecosystem-direction-guide.md`](briefs/2026-11-24-purple-ecosystem-direction-guide.md).
**Status:** **Proposed direction — awaiting owner review.** Documentation only. No application code, schema, migrations, storage, auth, dependencies or environments were changed. **Phase 1b stays the immediate priority (W7 next).**
**Decision record:** [`decisions/ADR-004-purple-ecosystem-direction.md`](decisions/ADR-004-purple-ecosystem-direction.md)

Companion documents:
- [`PURPLE-DIVISIONS-AND-CATEGORIES.md`](PURPLE-DIVISIONS-AND-CATEGORIES.md): the three divisions, how they map onto today's sections, categories and listing types, and what that means for onboarding
- [`PURPLE-MARKETING-INTELLIGENCE.md`](PURPLE-MARKETING-INTELLIGENCE.md): Insights, Coach, Growth Assistants, Customer Connection, Campaigns, guardrails and the AI approach
- [`PURPLE-FEATURE-INTEGRATION-MAP.md`](PURPLE-FEATURE-INTEGRATION-MAP.md): every capability in the brief, classified against the repository with evidence
- [`ROADMAP.md`](ROADMAP.md) v0.2: the single roadmap, now with the ecosystem overlay

Labels: **[Fact]** = verified in the repository (`phase-1b-foundation` @ `c72978a` + `docs/expansion-integration-plan` @ `ecc9c31`). **[Proposal]** = recommendation. **[Decision]** = needs the owner.

---

## 1. Vision

Purple grows from a creative-commerce marketplace into **one connected business ecosystem**. It helps people discover businesses, connect with customers, win work, look after customer relationships and grow sustainably. The aim is to be genuinely useful to every seller and service provider, not to be the biggest catalogue.

- **Product sellers** attract customers and sell more.
- **Handy professionals** get discovered, receive enquiries and bookings, and build trust.
- **Freelancers and professionals** show their skills, find clients and win projects.
- **Customers** find products, services and skilled people in one place.

**Free participation principle.** Listing, being found, receiving enquiries and core business guidance never depend on paying. Paid promotion adds visibility only, and it is always labelled. This matches decisions already on record: the free founding plan, a basic plan that stays free for good, and **Sponsored** labels on every paid placement (`PHASE-1B-PLAN.md` A10).

## 2. Structure: one parent, three divisions

| Division | For | Today's closest equivalent [Fact] |
|---|---|---|
| **Purple Shop**: products and commerce | Businesses selling physical (and digital) products | `listings.type = 'product'` across the Creative categories (Fashion & Adire, Art & Crafts, Digital & Design) |
| **Purple Handy Pro**: hands-on and local services | Plumbers, electricians, mechanics, cleaners, AC and generator technicians, builders | `home-services` section and category, `service_areas`, `working_hours`, `bookings` (schema), ID-before-listing rule |
| **Purple Professionals**: freelance, tech and creative services | Developers, designers, photographers, writers, marketers, consultants, virtual assistants | `listings.type in ('service','talent')` in Freelance and Creative categories, plus `/pro/[username]` professional profiles |

Detail and edge cases: `PURPLE-DIVISIONS-AND-CATEGORIES.md`.

### 2.1 Naming conflict to resolve [Decision ECO-D1]
**"Purple Shop" is currently the name of the whole site [Fact].** It's in the logo ("purple | shop"), migration `rename_purple_shop`, page titles and the README. Under this direction it becomes the name of **one division**, and the parent becomes **Purple**.

[Proposal] Change nothing public yet. Keep the site called Purple Shop until the Handy Pro and Professionals journeys exist (roadmap S6). Then rename in one deliberate step: parent brand, logo, page titles and, if wanted, the domain. Renaming earlier would advertise divisions that don't have working journeys yet.

## 3. One connected platform

The divisions get **their own catalogue fields, onboarding steps, Studio views and customer journeys**. Everything else is shared, and almost all of it already exists:

| Shared capability | Exists today [Fact] |
|---|---|
| One account and identity | `profiles` (one row per person; shop page and pro page are views of it) |
| Messaging | `start_conversation` / `send_message`, contact-details blocker, blocks |
| Reviews and trust | `reviews` (completed jobs only, schema), ID verification, verified badge, reports, risk flags, audit log |
| Search and discovery | Search over listings and sellers in every category; category pages |
| Promotions | A10 promotion registry (designed for Phase 3): product, service, talent, store, pro page and video boosts |
| Analytics | `story_events` (live) and `listing_events` (table only, never written) |
| Payments | Paystack via Edge Functions (O3, approved design; not built) |
| Safety, moderation and support | `can_post()` 2FA gate, account status, moderation queue functions |

**A business is not locked into one division.** This already holds: a seller can list a product and a service from the same account, because `type` sits on each listing, not on the seller [Fact]. The divisions should keep it that way (`PURPLE-DIVISIONS-AND-CATEGORIES.md` §4).

**No separate apps, no duplicate systems, no architecture redesign.** Nothing found during inspection needs one.

## 4. Purple Marketing Intelligence (summary)

MI is a capability **inside Business Studio (`/sell`)**, not a separate app. It has five parts: Insights, Marketing Coach, category-specific Growth Assistants, Customer Connection Assistant and Campaign Assistant. They're built in this order:

**trustworthy events → transparent metrics and rules → AI explanations → measured experiments.**

Full design, guardrails and cost controls: `PURPLE-MARKETING-INTELLIGENCE.md`.

Two findings shape it [Fact]:
1. **There's almost no measurement yet.** Listing views, profile views and enquiries aren't recorded; only story events are. MI can't say anything true about a business until the events model (roadmap S2) exists.
2. **"Sellers cannot contact buyers first" is a standing safety rule** (owner decision, enforced in messaging). The Customer Connection Assistant must work inside that rule: platform-sent, opt-in, post-transaction messages only. Sellers don't get new ways to message customers out of the blue. This needs a **consent and notification-preferences model that doesn't exist yet** (ECO-D7).

## 5. Unified discovery

Universal search is **partly built [Fact]**: `search_listings` and `search_sellers` already cover every category and both listing kinds and sellers from one search box. The future work is division badges, division filters, location and availability filters for Handy Pro, and division-aware ranking. Existing search is **not** replaced (`PURPLE-FEATURE-INTEGRATION-MAP.md` §8).

## 6. Principles carried forward

All the brief's engineering principles (§9) and ethical guardrails (§6) are adopted as written. They match the rules already in force:
- ADR-001 change freeze
- rules enforced in the database
- anonymous analytics
- Sponsored labels
- verified-only reviews
- no seller-first contact
- prices and quotas admin-configurable

Additions from inspection:
- **No new identity, money or promotion system per division.** A division is a lens over shared tables (see the divisions doc §3).
- **MI never shows a number it didn't measure.** Estimates and AI text are labelled as such.
- **Every new data type is added to privacy export and deletion in the migration that creates it** (the existing pattern from migration 011).

## 7. How this relates to earlier plans

| Earlier plan | Status | Relationship |
|---|---|---|
| Master brief: Revenue, Marketing & Video Monetization (16 Nov), Phases 2–5 | Phase 1b approved and in progress | Unchanged. Its promotions and campaigns are the **Campaign Assistant's** foundation |
| Phase 1b plan v1.2 | In progress: W1–W6 done, **W7 next** | **Untouched.** Not delayed, expanded or reprioritised by this direction |
| Expansion Integration Plan / ADR-003 (23 Nov), twelve modules, D-E1–D-E9 | Proposed, not yet answered | **Kept and re-framed.** The modules become features of divisions or of MI (feature map §9). Proposed change: core division journeys and measurement come before Community, Live and Rewards (ROADMAP v0.2) |

## 8. What this direction does *not* authorise

Copied from the brief (§13) and in force:
- no application code
- no schema, migration, RLS, storage or production setting changes
- no auth, registration, navigation or journey changes
- no dependencies
- no AI, analytics events, payments or campaigns
- no deployment
- no file moves or deletions

Each roadmap stage gets its own scoped plan and approval.

## 9. Decisions for the owner

Consolidated list with recommendations: **ADR-004 §Decisions (ECO-D1–ECO-D12)** and `PROJECT_STATUS.md`.
