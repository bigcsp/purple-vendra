# Purple Shop — Project Status

Master brief: *Purple Shop Revenue, Marketing & Video Monetization Project Plan v1.0* (16 Nov 2026).
Workflow: inspect → report → plan → **owner approval** → implement narrowly → integrate → test → report and pause.

## Current phase
**Phase 1b — Foundation: approved 16 Nov 2026, in progress.** Plan: [`docs/PHASE-1B-PLAN.md`](docs/PHASE-1B-PLAN.md) v1.2.
Approvals and conditions: [`docs/decisions/ADR-002-phase-1b-approvals.md`](docs/decisions/ADR-002-phase-1b-approvals.md).
Production change freeze: [`docs/decisions/ADR-001-production-change-freeze.md`](docs/decisions/ADR-001-production-change-freeze.md).

## Next approved task
**W6 accepted (19 Nov 2026). Staging seed replaced with w6-2 and verified.** Next: **W7** automated test harness. Not started; it begins only on the owner's go-ahead, as a separate scope.

## Purple Ecosystem direction (proposed 24 Nov 2026, awaiting review)
Brief: *Purple Ecosystem — Product Direction & Smart Marketing Project Guide* (24 Nov 2026), kept at [`docs/briefs/2026-11-24-purple-ecosystem-direction-guide.md`](docs/briefs/2026-11-24-purple-ecosystem-direction-guide.md).
**No feature implementation was authorised by this planning task.** No application code, schema, migrations, RLS, storage, auth, navigation, dependencies, environments or data were changed. **Phase 1b stays the immediate priority (W7 next); its scope is not expanded or delayed.**

Direction: one parent, **Purple**, with three divisions, **Purple Shop** (products), **Purple Handy Pro** (hands-on and local services) and **Purple Professionals** (freelance, tech, creative), plus **Purple Marketing Intelligence** inside Business Studio.

The direction umbrellas the expansion plan below, which stays valid with its modules re-homed under the divisions.

| Document | Purpose |
|---|---|
| [`docs/PURPLE-ECOSYSTEM-DIRECTION.md`](docs/PURPLE-ECOSYSTEM-DIRECTION.md) | Vision, structure, principles, relation to earlier plans |
| [`docs/PURPLE-DIVISIONS-AND-CATEGORIES.md`](docs/PURPLE-DIVISIONS-AND-CATEGORIES.md) | Divisions vs today's sections, categories and listing types; division model; onboarding; verification |
| [`docs/PURPLE-MARKETING-INTELLIGENCE.md`](docs/PURPLE-MARKETING-INTELLIGENCE.md) | Insights, Coach, Growth Assistants, Customer Connection, Campaigns; event taxonomy; guardrails; AI cost controls |
| [`docs/PURPLE-FEATURE-INTEGRATION-MAP.md`](docs/PURPLE-FEATURE-INTEGRATION-MAP.md) | Every brief capability classified (implemented / partial / needs improvement / new / future) with evidence |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) v0.2 | Single roadmap with the ecosystem overlay and acceptance criteria |
| [`docs/decisions/ADR-004-purple-ecosystem-direction.md`](docs/decisions/ADR-004-purple-ecosystem-direction.md) | Decision record; owner decisions ECO-D1–ECO-D12 |

Key findings:
- The existing `sections` (Creative / Freelance / Home Services) don't line up with the divisions. Divisions are therefore **derived** from listing type + category, with no schema change.
- "Purple Shop" is today's whole-site brand (ECO-D1).
- Listing events and notifications are never written, so MI starts with the S2 events model.
- There's no consent model, and "sellers cannot contact buyers first" constrains the Customer Connection Assistant (ECO-D7).

Open questions: ECO-D1–ECO-D12 (ADR-004), to be answered together with D-E1–D-E9 (ADR-003).

## Product expansion plan (proposed 23 Nov 2026, awaiting review)
Directive: *Purple Shop Product Expansion & Project Integration Directive* (23 Nov 2026). **Docs only; no implementation, no DB or dependency changes. Phase 1b stays the immediate priority.**
- Plan: [`docs/EXPANSION-INTEGRATION-PLAN.md`](docs/EXPANSION-INTEGRATION-PLAN.md) — what exists, what to upgrade/add, where each module belongs, connections, priorities, decisions D-E1–D-E9.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/FEATURE-MAP.md`](docs/FEATURE-MAP.md) · [`docs/ROADMAP.md`](docs/ROADMAP.md) (proposed single roadmap S1–S8) · [`docs/decisions/ADR-003-product-expansion-integration.md`](docs/decisions/ADR-003-product-expansion-integration.md)

| Module | Today | Proposed stage |
|---|---|---|
| Purple Stories · Purple Request | Live; upgrades planned | S2 / S5 / S6 |
| Purple Professional | Step 1 live | Steps 2–3 at S6 |
| Purple Discover · Business Studio · My Purple World | Partly built (homepage/search, Seller hub, `/account`) | S4 |
| Purple Business Spotlight | Partly built (schema + A10 design) | S5 with Phase 3 |
| Purple Match | New, built inside Requests | S6 |
| Purple Deals · Purple Rewards | New / schema only; need checkout | S7 |
| Purple Community · Purple Live | New; highest risk | S8 (Live: spike first) |

Shared foundations first: notification centre, events model (S2), checkout & escrow (S3).

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
| Expansion modules (ADR-003) | **Plan proposed 23 Nov 2026**; maps onto Phases 2–5 via `docs/ROADMAP.md` S2–S8 if D-E1 is approved |
| Purple Ecosystem direction (ADR-004) | **Proposed 24 Nov 2026**; mapping and docs done; overlays `docs/ROADMAP.md` v0.2 if ECO-D2 is approved. No implementation authorised |

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
| 23 Nov 2026 | ADR-003 expansion integration plan; D-E1–D-E9 (single roadmap, notification channels, personalisation data, follower privacy, keep URLs, non-cash rewards, bookings after escrow, Live spike, cleanup X1–X2) | **Proposed**, awaiting owner |
| 24 Nov 2026 | ADR-004 Purple Ecosystem direction; ECO-D1–ECO-D12 (brand timing, adopt direction + roadmap v0.2, new Shop categories, talent division, ratings, onboarding placement, customer-connection consent, verification per division, AI provider/budget, Handy Pro media, testimonials, answer D-E1–D-E9 + O15) | **Proposed**, awaiting owner |

## History
- 24 Nov 2026: Purple Ecosystem direction brief received. Repo inspected (`phase-1b-foundation` `c72978a`, `docs/expansion-integration-plan` `ecc9c31`; migrations, sections and categories, listing types, signup, Studio, events, notifications, bookings). Five planning docs + ADR-004 written; `ROADMAP.md` updated to v0.2. No code, DB, auth, storage or dependency changes; no feature implementation authorised.
- 23 Nov 2026: Product expansion directive received. Repo inspected (`main` `d7a0011`, `phase-1b-foundation` `c72978a`); integration plan, architecture, feature map, roadmap and ADR-003 written. No code, DB or dependency changes.
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
- Dead duplicate code: `src/app/actions/*.ts` (12 files) and `src/lib/{auth,catalog,messages,requests,search,stories,verification,seller}.ts` are older copies of `src/server/*` that nothing imports. Removal proposed as X1–X2 (after W7), not done.
- See audit §5 (R1–R9).
