# Purple Shop — Project Status

Master brief: *Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0* (16 Nov 2026).
Workflow: inspect → report → plan → **owner approval** → implement narrowly → integrate → test → report and pause.

## Current phase
**Phase 1b — Foundation: approved 16 Nov 2026, in progress.** Plan: [`docs/PHASE-1B-PLAN.md`](docs/PHASE-1B-PLAN.md) v1.2.
Approvals and conditions: [`docs/decisions/ADR-002-phase-1b-approvals.md`](docs/decisions/ADR-002-phase-1b-approvals.md).
Production change freeze: [`docs/decisions/ADR-001-production-change-freeze.md`](docs/decisions/ADR-001-production-change-freeze.md).

## Next approved task
W1 → W2 → W3/W4 → W5, then **stop at checkpoint C1** (migration mapping + schema diff) for owner review.

## Workstream tracker (Phase 1b)
| # | Workstream | Status |
|---|---|---|
| W1 | Change control & records | In progress |
| W2 | Production schema capture (read-only) | Not started |
| W3 | Content-level mapping, reconstruct 011 | Not started |
| W4 | Staging environment | Not started |
| W5 | Clean rebuild + schema diff | Not started |
| **C1** | **Owner review of mapping + diff** | — |
| W6 | Synthetic seed + anonymizer | Blocked by C1 |
| W7 | Test harness | Blocked by C1 |
| W8 | CI/CD pipeline | Blocked by W7 |
| W9 | Staging trial of P2/P3 | Blocked by W7 |
| W10 | Verifier + storage move demo (staging) | Can start after W4 |
| W11 | Admin recovery rehearsal (staging) | Can start after W4 |
| W12 | Phase 1b report | Last |

## Phase tracker
| Phase | Status |
|---|---|
| 1 Technical audit | Delivered |
| 1b Foundation | **Approved, in progress** |
| 2 Founding Free Plan + video limits | Not started; needs separate approval |
| 3 Featured Promotions | Not started; needs separate approval |
| 4 Purple Business Campaigns | Not started; needs separate approval |
| 5 Marketing ecosystem | Not started |

## Decisions
| Date | Decision | Status |
|---|---|---|
| 16 Nov 2026 | O1 staging free project (eu-west-2) | Approved |
| 16 Nov 2026 | O2a read-only production catalog capture, no data | Approved |
| 16 Nov 2026 | O3 Paystack + Supabase Edge Functions (no build in 1b) | Approved |
| 16 Nov 2026 | O14 break-glass admin account (design) | Approved |
| 16 Nov 2026 | O15 prepare repo to go private after secrets review | Approved |
| 16 Nov 2026 | P1 history alignment, P2 limit_saves revoke, P3 leaked-password protection | **Not approved**; present separately |
| — | O4–O13 | Before Phase 2/3 |

## History
- 16 Nov 2026: Phase 1 audit delivered (`docs/PHASE-1-AUDIT.md`).
- 16 Nov 2026: Plan v1.1, then v1.2 (`docs/PHASE-1B-PLAN.md`), mapping (`docs/MIGRATION-MAPPING.md`), cost model (`docs/cost-model.py`).
- 16 Nov 2026: Phase 1b approved with conditions (ADR-002). Freeze in force (ADR-001).

## Migrations
None applied anywhere in Phase 1b so far. Log: [`docs/DB-CHANGELOG.md`](docs/DB-CHANGELOG.md).

## Tests
None exist yet. CI runs lint, type check, build and npm audit only.

## Known issues
- Migration 011 is missing from the repo, so a clean rebuild fails at 012. The 4 production-only history rows are folded into repo files 014/016/020.
- `storage-cleanup` Edge Function is publicly callable (`verify_jwt: false`); low risk; P4 (Phase 2).
- Leaked-password protection requires Supabase Pro.
- See audit §5 (R1–R9).
