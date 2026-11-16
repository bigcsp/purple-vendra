# Purple Shop — Project Status

Master brief: *Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0* (16 Nov 2026).
Workflow: inspect → report → plan → **owner approval** → implement narrowly → integrate → test → report and pause.

## Current phase
**Phase 1 — Technical audit: delivered 16 Nov 2026, awaiting owner approval.**
Full report: [`docs/PHASE-1-AUDIT.md`](docs/PHASE-1-AUDIT.md)

## Revisions
- 16 Nov 2026: Owner asked for a refined plan (video quarantine, quota security, founding membership, payment security, admin system, hosting costs, DB recovery, testing/deployment). Delivered as [`docs/PHASE-1B-PLAN.md`](docs/PHASE-1B-PLAN.md) v1.1, with decisions O1–O13. Cost model: `docs/cost-model.py`.

- 16 Nov 2026: Owner asked for 7 final clarifications. Delivered plan v1.2 (quota accounting, migration mapping, storage move verification, reproducible cost model, W9 staging-only, promotion architecture for all seller types, admin recovery) plus [`docs/MIGRATION-MAPPING.md`](docs/MIGRATION-MAPPING.md).

## Next approved task
None yet. Waiting for formal Phase 1b approval and O1, O2a, O3. Production actions P1–P3 need separate approval.

## Phase tracker
| Phase | Status |
|---|---|
| 1 Technical audit | Delivered, awaiting approval |
| 1b Foundation | Plan v1.2 delivered, awaiting formal approval (est. 10–12 working days) |
| 2 Founding Free Plan + video limits | Not started |
| 3 Featured Promotions (+ minimal admin) | Not started |
| 4 Purple Business Campaigns | Not started |
| 5 Marketing ecosystem | Not started |

## Decisions
| Date | Decision | Status |
|---|---|---|
| 16 Nov 2026 | D1–D8 listed in audit §8 | Awaiting owner |

## Files changed (this phase)
- `PROJECT_STATUS.md` (new)
- `docs/PHASE-1-AUDIT.md` (new)
- `docs/PHASE-1B-PLAN.md` (new, revised plan v1.1)
- `docs/cost-model.py` (v1.2: explicit formulas, verified pricing kept separate, cached/uncached egress)
- `docs/MIGRATION-MAPPING.md` (new, preliminary repo ↔ production mapping)

## Migrations
None this phase. Note: live DB has objects not in the repo (missing `011`, four live-only migrations, `storage-cleanup` Edge Function). See audit R1.

## Tests
None exist yet. CI runs lint, type check, build and npm audit only.

## Known issues
- Migration 011 is missing from the repo, so a clean rebuild fails at 012. The 4 production-only migrations are folded into repo files 014/016/020.
- `storage-cleanup` Edge Function is publicly callable (`verify_jwt: false`); low risk, fix proposed as P4 (Phase 2).
- Leaked-password protection requires Supabase Pro.
See audit §5 (R1–R9). Highest: DB drift, video quota bypass, no payment provider, no admin UI, no staging/tests.
