# Purple Shop — Project Status

Master brief: *Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0* (16 Nov 2026).
Workflow: inspect → report → plan → **owner approval** → implement narrowly → integrate → test → report and pause.

## Current phase
**Phase 1b — Foundation: approved 16 Nov 2026, in progress.** Plan: [`docs/PHASE-1B-PLAN.md`](docs/PHASE-1B-PLAN.md) v1.2.
Approvals and conditions: [`docs/decisions/ADR-002-phase-1b-approvals.md`](docs/decisions/ADR-002-phase-1b-approvals.md).
Production change freeze: [`docs/decisions/ADR-001-production-change-freeze.md`](docs/decisions/ADR-001-production-change-freeze.md).

## Next approved task
**W6 accepted (19 Nov 2026). Staging seed replaced with w6-2 and verified.** Next: **W7** automated test harness. Not started; it begins only on the owner's go-ahead, as a separate scope.

## Workstream tracker (Phase 1b)
| # | Workstream | Status |
|---|---|---|
| W1 | Change control & records | ✅ Done |
| W2 | Production schema capture (read-only) | ✅ Done (470 objects, md5 verified) |
| W3 | Content-level mapping, reconstruct 011 | ✅ Done; Option A layout applied (`002311a`) |
| W4 | Staging environment | ◐ Staging DB project created; Vercel/GitHub settings pending (owner) |
| W5 | Clean rebuild + schema diff | ✅ Done. After C1: 453/470 identical, 17 allowed, **0 unexplained** |
| C1 | Owner review of mapping + diff | ✅ Approved 19 Nov 2026 (Option A) |
| W6 | Synthetic seed + anonymizer | ✅ **Accepted** 19 Nov; staging holds seed w6-2 (replaced and verified) |
| W7 | Test harness | **Next** (awaiting go-ahead) |
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
| 19 Nov 2026 | W6 accepted; staging w6-1 seed replaced by w6-2 with fingerprint, verified backup, dry run, in-transaction verification | Approved (owner) |
| 19 Nov 2026 | W6 security remediation: seed allowlist guard, atomic seed, completion marker, admin password, bcrypt 10; anonymizer F1–F7; rollback-only staging tests with snapshot | Approved (owner) |
| 19 Nov 2026 | C1 accepted (acceptance criteria B4.1, B4.2 met); W6 then W7 approved, each after review; P1 still separate | Approved |
| 19 Nov 2026 | **C1:** Option A (A1–A9, repo + staging only), the allowed differences, reconstructed 011; P1 stays a separate approval | Approved |
| 16 Nov 2026 | P1 history alignment, P2 limit_saves revoke, P3 leaked-password protection | **Not approved**; present separately |
| — | O4–O13 | Before Phase 2/3 |

## History
- 16 Nov 2026: Phase 1 audit delivered (`docs/PHASE-1-AUDIT.md`).
- 16 Nov 2026: Plan v1.1, then v1.2 (`docs/PHASE-1B-PLAN.md`), mapping (`docs/MIGRATION-MAPPING.md`), cost model (`docs/cost-model.py`).
- 16 Nov 2026: Phase 1b approved with conditions (ADR-002). Freeze in force (ADR-001).
- 19 Nov 2026: W6 accepted. Staging seed replaced w6-1 → w6-2 (`1d8e522` scripts): fingerprint `a4390035…` → `9d41b419…`; backup 46 tables / 1,838 rows verified; only old-seed rows deleted (dry run); 32/32 in-transaction; suites 83/83 afterwards. Production unchanged.
- 19 Nov 2026: W6 security review (owner): seed guard FAIL, admin / atomicity / duplicates NEEDS ATTENTION, integrations PASS; anonymizer F1–F7. Remediation approved and done (`f558ab6`, `959ec52`); final run 83/83; staging unchanged (fingerprint). N1 (anonymizer substring target match) found and fixed during remediation.
- 19 Nov 2026: W6 delivered: synthetic seed loaded on staging, anonymizer built; tests 30/30 and 19/19. Staging runner token deleted.
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
Production: none applied in Phase 1b. Staging: rebuilt from the 26-file C1 layout on 19 Nov (`docs/schema/STAGING-REBUILD-2026-11-19.md`), then loaded with the synthetic seed (W6). Log: [`docs/DB-CHANGELOG.md`](docs/DB-CHANGELOG.md).

## Tests
On the live w6-2 seed (19 Nov, after replacement): seed 32/32, guard 19/19, anonymizer 31/31, live re-run refused. Earlier: W6 SQL suites (run on staging in one rolled-back block, `959ec52`): guard/atomicity G00–G15 19/19, seed S01–S32 32/32, anonymizer A01–A29 31/31; staging fingerprint unchanged (`a4390035…`). See `docs/W6-SEED-AND-ANONYMIZER.md` §4. Automated CI tests come in W7/W8. Before W6: CI runs lint, type check, build and npm audit only (green since `fc3832b`). Edge Functions currently have no CI type check; added in W8.

## Known issues
- Production migration history has no rows for 001–011 (applied by hand). Adding them is **P1**, not approved.
- `storage-cleanup` Edge Function is publicly callable (`verify_jwt: false`); low risk; P4 (Phase 2).
- Leaked-password protection requires Supabase Pro.
- Leftover branch `trial/w8-deno-check` (W8 job trial, not for merge): owner asked for deletion 19 Nov; the agent's git proxy refuses branch deletion, so the owner deletes it on GitHub.
- Staging backup schema `w6_backup_20261119` (exact copy of the pre-replacement state, not API-exposed): keep until W8, then drop **with owner approval**.
- 20 old seller-register rows (seller_id null), plus the old seed's milestones, status history and security events, remain in append-only staging history by design (synthetic only).
- The Supabase CLI seeding path (`supabase db reset` with `alter database ... set purple.seed_target = 'local'`) is documented but not yet exercised (no local Docker in this workspace); W8 covers it.
- Pre-existing (not W6): `anon` holds SELECT grants on 7 private tables, protected by row-level security only (0 rows visible, checked). Cover with pgTAP in W7.
- Staging media files (listing images, story videos) are placeholders until W7/W10.
- `staging-migration-runner` Edge Function is now inert (its token was deleted 19 Nov); remove it in W8 when the pipeline replaces it.
- See audit §5 (R1–R9).
