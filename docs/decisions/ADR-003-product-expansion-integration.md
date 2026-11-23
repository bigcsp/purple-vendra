# ADR-003: Integrate the product expansion modules into the existing Purple Shop

- **Status:** proposed
- **Date:** 2026-11-23
- **Approved by:** — (awaiting owner review)
- **Phase:** cross-phase (planning only; Phase 1b remains current)

## Context
The owner's *Product Expansion & Project Integration Directive* (23 Nov 2026) proposes twelve modules (Discover, Stories, Request, Live, Rewards, Business Studio, Professional, Deals, Community, Match, Business Spotlight, My Purple World) and supporting features. It requires extending the existing project, preserving functionality and security, keeping Phase 1b first, and no implementation before approval.

Inspection [Fact]: Stories, Requests and Professional (step 1) are live; Discover, Studio, Spotlight and My Purple World are partly present under other names; notifications, bookings, reviews, referrals and listing events exist as schema only; there is no payment provider. Details: `docs/EXPANSION-INTEGRATION-PLAN.md`.

## Options considered
1. **Separate apps or services per module.** Clear ownership, but duplicates users, payments and safety rules; violates the directive.
2. **Build modules in the order listed.** Simple, but Deals/Rewards/Bookings/Reviews would stall on missing payments and each would invent its own notifications and analytics.
3. **Integrate modules into the existing domains, after three shared foundations (notifications, events, checkout & escrow), in a dependency-ordered roadmap.**

## Decision (proposed)
Option 3. Keep existing URLs (`/sell` = Business Studio, `/account` = My Purple World), one identity, one money path, one promotion registry, anonymous analytics. Adopt `docs/ROADMAP.md` as the single roadmap (D-E1). Defer Community and Live to the last stage; Live starts with a costed spike.

## Consequences
- No change to current code, databases or Phase 1b scope from this ADR.
- Some visible modules (Deals, Rewards) arrive after checkout, later than a feature-first order would suggest.
- New external services limited to an email provider and, possibly, a live-video provider, each with its own approval.
- Undo: this is documentation; reject or revise the plan.

## Evidence
`docs/EXPANSION-INTEGRATION-PLAN.md`, `docs/ARCHITECTURE.md`, `docs/FEATURE-MAP.md`, `docs/ROADMAP.md`; repo inspection of `main` @ `d7a0011` and `phase-1b-foundation` @ `c72978a`.
