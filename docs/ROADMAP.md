# Purple — Development Roadmap (proposed single roadmap)

**Status:** **Proposed (D-E1 + ECO-D2), awaiting owner approval.** Until approved, the tracker in `PROJECT_STATUS.md` remains authoritative.
Merges the README backend steps 6–9, the master-brief Phases 2–5, the expansion modules (ADR-003) and the **Purple Ecosystem direction** (ADR-004: three divisions + Marketing Intelligence) into one sequence.
Each stage gets its own scoped plan, owner approval, staging run and tests before production (ADR-001). Durations are rough planning ranges, not commitments.

## Stages

| Stage | Contents | Ecosystem additions (v0.2) | Hard prerequisites | Rough size |
|---|---|---|---|---|
| **S1 — Phase 1b Foundation** *(in progress)* | W7 test harness, W8 CI/CD (+ Deno check), W9 staging trial P2/P3, W10 verifier + storage move, W11 admin recovery, W12 report | **None.** Not expanded or delayed | — | per 1b plan |
| **S2 — Phase 2 + shared foundations** | Founding Free Plan, video quota and quarantine (A1–A3), `platform_settings`; notification centre; events model; price-history recording; Request offer notifications; cleanup X1–X2 | Events model uses the **MI event taxonomy** (MI doc §4): listing/profile/pro views, enquiry `source`, quote events. **Design** of notification preferences and consent (ECO-D7); build only the in-app opt-out | S1 accepted | 2–3 weeks |
| **S3 — Checkout & escrow** | Paystack via Edge Functions, `payments`/`payment_events`, `confirm_payment()`, orders, delivery confirmation, payouts (manual first), basic disputes | **Shop core journey complete** (browse → buy → deliver → confirm). Service orders use the same path | S2; Paystack account + test keys; D3 | 3–4 weeks |
| **S4 — Hubs, discovery & Insights** | My Purple World + Following; Business Studio + Insights; price and restock alerts; Discover v1; admin screens | **Insights v1** (measured only), **Coach v1** (rules table + admin), seller-facing **demand insights**, derived **division badges** and **area filter** in search | S2 (S3 for order metrics) | 3–4 weeks |
| **S5 — Promotions & Spotlight** | Featured Promotions (A10), Business Spotlight (paid + editorial), Video Promotion replaces budget campaigns (D1) | Campaign Assistant v1 (package choice + recorded-event reports) | S3, S4 admin, events | 2–3 weeks |
| **S6 — Division core journeys** | Bookings, reviews, Purple Match v1, Professional steps 2–3, request → booking/checkout | **Handy Pro:** sub-categories, booking calendar, job status, before/after portfolio. **Professionals:** package tiers, consultations, project status. **Onboarding:** Studio "What do you offer?" + division checklists (`seller_divisions`). **Customer Connection v1:** platform-sent review requests + opt-in reminders. **Brand decision (ECO-D1)** taken at the end of S6 | S3, S2 notifications + ECO-D7 | 4–6 weeks |
| **S7 — Growth commerce & assisted marketing** | Purple Deals, Purple Business Campaigns (Phase 4), WhatsApp share kit | Category **Growth Assistants**; **AI assistance** (explain, draft) if ECO-D9 is approved; new Shop categories if ECO-D3 is approved | S5, S6 | 4–6 weeks |
| **S8 — Deferred / experimental** | Purple Rewards (non-cash, D-E6), Purple Community, Purple Live (spike first) | MI experimentation (A/B), cross-division recommendations, intent search ("bedroom makeover") | S4 admin; S7 data quality and cost review; D-E8 | TBD |

## Acceptance criteria (summary per stage; full criteria in each stage plan)

| Stage | Done means |
|---|---|
| S2 | Each event type in the taxonomy is written once per real action (pgTAP + Playwright). No user id stored in counting events. Enquiries carry a source. Notification centre shows request-offer alerts. Production unchanged until separately approved. |
| S3 | A Paystack test-mode payment activates an order **only** via a verified webhook. A duplicate webhook gives one activation; a wrong amount gives none. Buyer confirmation releases escrow state. |
| S4 | Every Insights number traces to recorded events (reconciliation query). An "insufficient data" state shows below the minimum. Coach tips can be accepted, edited or dismissed, and are admin-editable. Division badge matches the derivation rule for every seeded listing. |
| S5 | Paid placements labelled Sponsored everywhere; organic results never removed; reports show recorded events only. |
| S6 | A Handy Pro can take a booking from request to completed to review. A professional can win a request and get paid through checkout. A multi-division seller sees both checklists. Reminders are sent only to opted-in customers and never more than the configured cap. |
| S7 | AI outputs never contain a number, date or stock count that isn't in the input (validator tests). Per-seller and global spend caps enforced. Kill switch tested. |

## Ordering rationale
- **Foundations before features.** Notifications, events and payments are each needed by 5+ modules and by every MI part.
- **Measure before advising.** MI starts with honest counts (S4); rules come before AI; AI comes before experiments.
- **Core journeys before extras (v0.2 change).** Each division's basic journey (sell → deliver; book → complete; propose → deliver) comes before Rewards, Community and Live, which move to S8.
- **Money before money features.** Bookings, reviews, Deals, Rewards and paid Spotlight need escrow checkout.
- **Highest risk last.** Community (moderation), Live (provider, egress) and AI (recurring cost) wait for admin tooling, data and revenue.
- **Supabase Pro** (O10) should land with S2 go-live, as already recommended.

## Brief phases → stages

| Ecosystem brief (§10) | Roadmap |
|---|---|
| Phase 0 Current foundation | S1 |
| Phase 1 Product and architecture mapping | Done as documentation (24 Nov 2026): this file, ADR-004 and companions |
| Phase 2 Core business journeys | S3 (products), S6 (services, projects) |
| Phase 3 Measurement and insights | S2 (events), S4 (Insights) |
| Phase 4 Marketing intelligence | S4 (Coach v1), S5–S7 (assistants) |
| Phase 5 Advanced intelligence and discovery | S7 (AI), S8 (experiments, universal intent search) |

## Change log
- 24 Nov 2026: v0.2 proposed. Ecosystem overlay (ADR-004): MI event taxonomy in S2; Insights and Coach in S4; S6 becomes division core journeys; AI in S7; Rewards moved from S7 to S8; acceptance criteria added.
- 23 Nov 2026: v0.1 proposed with the expansion integration plan.
