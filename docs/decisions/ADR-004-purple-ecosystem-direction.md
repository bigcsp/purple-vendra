# ADR-004: Purple Ecosystem direction — three divisions and Marketing Intelligence

- **Status:** proposed
- **Date:** 2026-11-24
- **Approved by:** — (awaiting owner review)
- **Phase:** cross-phase (planning only; Phase 1b remains current, W7 next)

## Context
The owner's *Purple Ecosystem — Product Direction & Smart Marketing Project Guide* (24 Nov 2026; `docs/briefs/2026-11-24-purple-ecosystem-direction-guide.md`) redirects the long-term product vision:
- One parent, **Purple**, with three divisions: **Purple Shop** (products), **Purple Handy Pro** (hands-on and local services) and **Purple Professionals** (freelance, tech and creative services).
- **Purple Marketing Intelligence** inside the seller experience.
- Documentation only; nothing implemented before approval.

Inspection [Fact] (`docs/PURPLE-FEATURE-INTEGRATION-MAP.md`):
- A `sections` table already models three marketplaces (Creative / Freelance / Home Services). It splits by industry, not by what is sold, so it doesn't line up with the divisions.
- `listing_type` (product/service/talent) plus category does identify the division of every listing.
- Handy Pro foundations exist: service areas, working hours, the ID-before-listing rule, `bookings` (schema), quotes via Requests.
- Measurement is almost absent: `listing_events` and `notifications` are never written, and there's no consent model.
- "Purple Shop" is today's whole-site brand.
- ADR-003 (23 Nov, twelve modules) is still proposed.

## Options considered
1. **Three separate apps or brands.** Duplicates identity, money, safety and reviews. Rejected by the brief.
2. **Rename `sections` to the three divisions.** Quick, but misfiles creative services (photography, design commissions, talent) into a product division, and changes the homepage and listing form.
3. **Derive the division from listing type + category; add a seller division preference later; keep all shared systems; build MI in measured stages.**

## Decision (proposed)
Option 3:
- The division is a lens, not a new system (`PURPLE-DIVISIONS-AND-CATEGORIES.md` §3).
- MI lives inside Business Studio: events → rules → AI → experiments (`PURPLE-MARKETING-INTELLIGENCE.md`).
- `docs/ROADMAP.md` v0.2 becomes the single roadmap: core division journeys and measurement come before Rewards, Community and Live.
- ADR-003 modules are kept and re-homed under the divisions.

## Consequences
- No change to code, databases, auth, storage, navigation or Phase 1b scope from this ADR.
- The public site stays "Purple Shop" until ECO-D1 is decided (proposed: end of S6).
- MI arrives gradually; the first useful version (Insights v1) depends on the S2 events model.
- Customer Connection is constrained by the no-seller-first-contact rule and needs a consent model.
- Undo: this is documentation; reject or revise.

## Decisions requested from the owner

| # | Decision | Recommendation |
|---|---|---|
| ECO-D1 | Parent brand: "Purple Shop" (today the whole site) becomes one division; the parent is "Purple". When to rename the site, logo, titles, domain? | Change nothing public now; decide at the end of S6, once all three journeys work |
| ECO-D2 | Adopt this direction as the umbrella vision and `ROADMAP.md` v0.2 (includes moving Rewards from S7 to S8) | Approve |
| ECO-D3 | Open new Shop categories (electronics, beauty, home and furniture, food and groceries)? | Not yet. Keep the creative-commerce launch scope; evaluate each category with its own listing rules at S7. Food and groceries last |
| ECO-D4 | Which division do `talent` listings (models, make-up artists, performers) belong to? | Professionals by default |
| ECO-D5 | One aggregate rating or per-division ratings? | Aggregate in v1; per-division can be computed later |
| ECO-D6 | Where to ask "What do you offer?" | In Business Studio on first visit (multi-select), **not** at registration; registration flow unchanged |
| ECO-D7 | Customer Connection rules | Platform-sent, opt-in, post-transaction only; keep "sellers cannot contact buyers first"; design notification preferences and consent in S2 before any reminder ships |
| ECO-D8 | Verification per division | As in the divisions doc §7: Handy Pro keeps mandatory ID; others optional badge |
| ECO-D9 | AI provider and budget | Decide at S7, after Insights v1 is live; on-demand, capped, cached, server-side only |
| ECO-D10 | Photos and videos in Handy Pro problem descriptions (Requests are text-only by earlier decision) | Defer to S6; re-run the cost model and moderation plan first |
| ECO-D11 | Off-platform testimonials for Professionals | Don't mix with reviews; if allowed, show separately as "Client quote — not verified by Purple" |
| ECO-D12 | Answer ADR-003 D-E1–D-E9 together with this ADR; complete O15 (make the repo private) now that strategy docs live in it | Approve |

## Evidence
`docs/PURPLE-ECOSYSTEM-DIRECTION.md`, `docs/PURPLE-DIVISIONS-AND-CATEGORIES.md`, `docs/PURPLE-MARKETING-INTELLIGENCE.md`, `docs/PURPLE-FEATURE-INTEGRATION-MAP.md`, `docs/ROADMAP.md` v0.2. Repository inspection of `phase-1b-foundation` @ `c72978a` and `docs/expansion-integration-plan` @ `ecc9c31`.
