# Purple Shop — Development Roadmap (proposed single roadmap)

**Status:** **Proposed (D-E1), awaiting owner approval.** Until approved, the tracker in `PROJECT_STATUS.md` remains authoritative.
Merges the README backend steps 6–9, the master-brief Phases 2–5 and the expansion modules into one sequence.
Each stage gets its own scoped plan, owner approval, staging run and tests before production (ADR-001). Durations are rough planning ranges, not commitments.

| Stage | Contents | Replaces / includes | Hard prerequisites | Rough size |
|---|---|---|---|---|
| **S1 — Phase 1b Foundation** *(in progress)* | W7 test harness, W8 CI/CD (+ Deno check), W9 staging trial P2/P3, W10 verifier + storage move, W11 admin recovery, W12 report | Phase 1b | — | per 1b plan |
| **S2 — Phase 2 + shared foundations** | Founding Free Plan, video quota & quarantine (A1–A3), `platform_settings`; **notification centre**; **events model** (start writing listing views); **price-history recording**; Request offer notifications; cleanup X1–X2 | Phase 2; README step 6 "alerts" | S1 accepted | 2–3 weeks |
| **S3 — Checkout & escrow** | Paystack via Edge Functions, `payments`/`payment_events`, `confirm_payment()`, orders flow, delivery confirmation, payouts (manual first), disputes basic | README step 7; A4/O3 | S2; Paystack account + test keys; D3 secret-key decision | 3–4 weeks |
| **S4 — Hubs & discovery** | My Purple World hub + Following; Business Studio rename + Insights; price & restock alerts; Discover v1 (feed, similar items); admin screens | README steps 8 (admin) & 9 (analytics) | S2 (S3 for order sections) | 3–4 weeks |
| **S5 — Promotions & Spotlight** | Featured Promotions (A10 registry, packages, Sponsored placements), Business Spotlight (paid + editorial), Video Promotion replaces budget campaigns (D1) | Phase 3 | S3, S4 admin, events model | 2–3 weeks |
| **S6 — Services & matching** | Bookings, Customer reviews, Purple Match v1, Professional steps 2–3, request → booking/checkout | — | S3 (bookings/reviews), S2 notifications | 3–4 weeks |
| **S7 — Growth commerce** | Purple Deals, Purple Business Campaigns, Purple Rewards (non-cash, D-E6), WhatsApp share kit → referral rewards | Phase 4; Phase 5 items | S3, S5 | 4–6 weeks |
| **S8 — Community & Live** | Purple Community (after moderation tooling proves out); Purple Live **spike** → build only if approved | Phase 5 | S4 admin; spike approval (D-E8) | spike 1 week; build TBD |

## Ordering rationale
- **Foundations before features.** Notifications, events and payments are each needed by 5+ modules; building them first means no module invents its own.
- **Money before money features.** Bookings, Reviews (need completed jobs), Deals, Rewards and paid Spotlight are meaningless without escrow checkout.
- **Cheap, high-UX wins early (S4).** My Purple World, Following, alerts and Studio Insights mostly re-present data that already exists.
- **Highest-risk last.** Community (moderation load) and Live (new provider, egress cost, real-time moderation) wait until admin tooling and revenue exist.
- **Supabase Pro** (O10) should land with S2 go-live as already recommended; video and alerts increase egress and email volume.

## Change log
- 23 Nov 2026: v0.1 proposed with the expansion integration plan.
