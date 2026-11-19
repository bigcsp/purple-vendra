# Purple Shop — Project Status

Master brief: *Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0* (16 Nov 2026).
Workflow: inspect → report → plan → **owner approval** → implement narrowly → integrate → test → report and pause.

## Current phase
**Phase 1b — Foundation: approved 16 Nov 2026, in progress.** Plan: [`docs/PHASE-1B-PLAN.md`](docs/PHASE-1B-PLAN.md) v1.2.
Approvals and conditions: [`docs/decisions/ADR-002-phase-1b-approvals.md`](docs/decisions/ADR-002-phase-1b-approvals.md).
Production change freeze: [`docs/decisions/ADR-001-production-change-freeze.md`](docs/decisions/ADR-001-production-change-freeze.md).

## Next approved task
**C1 approved and applied (19 Nov 2026).** Next: **W6** synthetic seed + anonymizer, then **W7** test harness. Staging is rebuilt from the C1 layout with 0 unexplained differences.

## Workstream tracker (Phase 1b)
| # | Workstream | Status |
|---|---|---|
| W1 | Change control & records | ✅ Done |
| W2 | Production schema capture (read-only) | ✅ Done (470 objects, md5 verified) |
| W3 | Content-level mapping, reconstruct 011 | ✅ Done; Option A layout applied (`002311a`) |
| W4 | Staging environment | ◐ Staging DB project created; Vercel/GitHub settings pending (owner) |
| W5 | Clean rebuild + schema diff | ✅ Done. After C1: 453/470 identical, 17 allowed, **0 unexplained** |
| C1 | Owner review of mapping + diff | ✅ Approved 19 Nov 2026 (Option A) |
| W6 | Synthetic seed + anonymizer | **Next** |
| W7 | Test harness | After W6 |
| W8 | CI/CD pipeline (now includes the Deno check for Edge Functions, see below) | Blocked by W7 |
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
| 19 Nov 2026 | Exclude `supabase/functions` from the Next.js type check (`tsconfig.json`); add a separate Deno check job in W8 | Approved |
| 19 Nov 2026 | **C1:** Option A (A1–A9, repo + staging only), the allowed differences, reconstructed 011; P1 stays a separate approval | Approved |
| 16 Nov 2026 | P1 history alignment, P2 limit_saves revoke, P3 leaked-password protection | **Not approved**; present separately |
| — | O4–O13 | Before Phase 2/3 |

## History
- 16 Nov 2026: Phase 1 audit delivered (`docs/PHASE-1-AUDIT.md`).
- 16 Nov 2026: Plan v1.1, then v1.2 (`docs/PHASE-1B-PLAN.md`), mapping (`docs/MIGRATION-MAPPING.md`), cost model (`docs/cost-model.py`).
- 16 Nov 2026: Phase 1b approved with conditions (ADR-002). Freeze in force (ADR-001).
- 19 Nov 2026: C1 approved; Option A applied (`002311a`); staging rebuilt, 0 unexplained differences; `escalate_report` gap closed in the repo.
- 18 Nov 2026: CI fixed (`fc3832b`): Edge Functions excluded from the Next.js type check. Approved by owner 19 Nov; Deno check added to W8.

## CI fix: Edge Functions excluded from the Next.js type check (18 Nov 2026)
**What changed.** `tsconfig.json` → `"exclude": ["node_modules", "supabase/functions"]`. One line, commit `fc3832b`. No application code changed.

**Why.** Edge Functions in `supabase/functions/` run on **Deno**, not Node. They use the `Deno` global and `jsr:` imports and are deployed by the Supabase CLI, never built by Next.js. The app's `tsconfig.json` includes `**/*.ts`, so once W3 added `storage-cleanup/index.ts`, the Next.js type check tried to compile it and failed (TS2307 `jsr:@supabase/supabase-js@2`, TS2304 `Deno`). This broke CI on every Phase 1b push (W1+W2, W3, W5+C1).

**Effect.**
- The Next.js type check, build and Vercel deployment are unchanged for app code. The exclusion only removes files Next.js never imports.
- Edge Function deployment is unaffected. The Supabase CLI bundles functions with its own Deno toolchain and never reads `tsconfig.json`.
- The function source is byte-identical to the deployed version (`storage-cleanup/DEPLOYED.md`).

**Follow-up (W8, approved 19 Nov 2026).** CI gets a separate `edge-functions` job that runs `deno check` and `deno bundle` on `supabase/functions/*/index.ts`, starting with `storage-cleanup`. It is independent of the Next.js `check` job, so either can fail without masking the other. It was trialled on GitHub runners on 19 Nov and passed. The job spec and evidence are in `docs/PHASE-1B-REPORT.md` §1. It goes into `ci.yml` when W8 starts; it is not pulled forward ahead of C1/W7.

This fix does not widen Phase 1b scope and authorises no production change.

## Migrations
Production: none applied in Phase 1b. Staging: rebuilt from the 26-file C1 layout on 19 Nov (`docs/schema/STAGING-REBUILD-2026-11-19.md`). Log: [`docs/DB-CHANGELOG.md`](docs/DB-CHANGELOG.md).

## Tests
None exist yet. CI runs lint, type check, build and npm audit only (green since `fc3832b`). Edge Functions currently have no CI type check; added in W8.

## Known issues
- Staging Vault still holds the one-time runner token (deletion needs owner confirmation in the connector).
- Production migration history has no rows for 001–011 (applied by hand). Adding them is **P1**, not approved.
- `storage-cleanup` Edge Function is publicly callable (`verify_jwt: false`); low risk; P4 (Phase 2).
- Leaked-password protection requires Supabase Pro.
- Leftover branch `trial/w8-deno-check` (W8 job trial, not for merge) needs deleting by the owner; the agent proxy can't delete branches.
- See audit §5 (R1–R9).
