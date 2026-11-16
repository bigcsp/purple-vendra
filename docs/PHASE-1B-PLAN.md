# Purple Shop — Revised Technical Plan & Phase 1b Implementation Plan

**Version:** 1.1 · 16 Nov 2026 · **Status:** awaiting owner approval. No application code or production database changes have been made.
**Supersedes:** §6 of `docs/PHASE-1-AUDIT.md`. The audit's findings (§2–§5) still stand.
**Labels:** **[Fact]** = verified in code, the live database or the provider's docs. **[Assumption]** = an estimate that needs confirming.

---

## Part A — How each requirement will be met

These are design specs. Phase 1b builds the foundation they need. The features themselves are built in the phase shown against each one.

### A1. Video security: private quarantine, then publish (built in Phase 2)

**Problem [Fact].** `story-media` is a public bucket, and today any 2FA seller can write straight into it. The browser reports the video's duration and the server never checks it.

**New flow:**

```
Seller's browser                Database (RPC / RLS)              Supabase Edge Function (service role)
────────────────                ─────────────────────             ─────────────────────────────────────
1. reserve_media_upload()  ──▶  locks quota, creates ticket,
                                returns server-made path in
                                PRIVATE bucket `story-uploads`
2. transcode (ffmpeg.wasm)
3. upload to that exact path ─▶ storage policy: path must match an
                                unexpired 'reserved' ticket owned
                                by the caller; no update/upsert
4. submit_story_upload()   ──▶  ticket → 'uploaded'; story row
                                created with status 'processing';
                                verification job queued  ─────────▶ 5. verify-story-media:
                                                                      • real size from storage metadata ≤ ticket max
                                                                      • magic bytes: ISO-BMFF (ftyp mp4/isom), not the claimed MIME type
                                                                      • parse moov/mvhd: duration ≤ max + 0.5 s
                                                                      • video track = H.264 (avc1), ≤ 1280 px, audio AAC or none
                                                                      • SHA-256 hash recorded
                                                                      • cover image: magic bytes, ≤ 500 KB, ≤ 1280 px
                                                                    6a. PASS → move file to public `story-media`
                                                                        (cross-bucket move is supported [Fact]),
                                                                        write server-measured duration, size and
                                                                        dimensions, set status draft/published as
                                                                        the seller chose, ticket → 'verified'
                                                                    6b. FAIL → delete the file, status 'media_rejected'
                                                                        with a plain-English reason, ticket → 'rejected'
```

- **Nobody can view a file before it's verified.** `story-uploads` is private and has no read policy for anyone, including the owner. The seller previews from the local copy in their browser.
- **Only the verifier can write to the public bucket.** The `story-media` insert, update and delete policies for `authenticated` are removed. Only the service role (inside the Edge Function) moves files in. Replacing a video goes through the same ticket flow.
- **Reading only the start of the file is enough.** The browser converter already writes the MP4 index at the start of the file (`-movflags +faststart` [Fact]), so the verifier only needs the first part of the file. A file without an index at the start is rejected.
- **The browser's numbers are only for display.** `duration_seconds`, `size_bytes`, `width` and `height` are overwritten with server-measured values. A database trigger refuses to set `status = 'published'` on a story whose media isn't verified.
- **Retries.** Jobs are queued in a `media_verification_jobs` table. The Edge Function is called right away (via `pg_net`), and a cron sweep every 5 minutes retries stuck jobs, up to 3 attempts. After that the story becomes `media_rejected (technical)` and the quota slot is released (see A2).
- **Content moderation.** Unchanged: reports, auto-hide after 3 reports, and admin moderation. An admin setting `video_requires_review` (default **off**) can hold verified videos for manual approval if abuse appears.
- **Backfill.** The 1 existing video [Fact] is run through the verifier once. It stays live if it passes.

### A2. Upload quota security (built in Phase 2; all enforcement in the database)

**Tables** (no RLS policies for users; they can only be changed through security-definer functions):

- `media_upload_tickets`:
  - `id`, `user_id`, `kind` (story_video / story_cover)
  - `path` (UNIQUE, server-generated, includes the ticket id)
  - `max_bytes`, `max_seconds` (snapshot of settings at reservation time)
  - `quota_period` (first day of the month, in **Africa/Lagos** time)
  - `status`: reserved → uploaded → verifying → verified | rejected | expired | cancelled
  - `story_id` (UNIQUE), `sha256`
  - `reserved_at`, `expires_at`, `consumed_at`
- `media_quota_usage (user_id, period, used, reserved)`, primary key `(user_id, period)`. This is the counter row.

| Threat | How it's blocked |
|---|---|
| **Simultaneous uploads** (5 tabs reserve at once) | `reserve_media_upload()` runs `SELECT … FOR UPDATE` on the user's usage row, so concurrent calls run one at a time. The check is `used + reserved < quota`, and only **1 open reservation** per user is allowed. |
| **Ticket reuse** | The storage policy accepts only `path = ticket.path`, `status = 'reserved'` and `expires_at > now()`. Submit moves the ticket on from `reserved`. There's no UPDATE policy on the quarantine bucket, so a file can't be overwritten or upserted. The unique `story_id` means one ticket gives exactly one story. |
| **Expired reservations** | The ticket lasts 30 minutes (configurable). Uploads after that are rejected by policy. Cron marks it `expired`, releases `reserved` and queues any stray file for deletion. |
| **Duplicate submits** (double-click, network retry) | `submit_story_upload(ticket)` is idempotent: a second call returns the same story. |
| **Same file uploaded twice** | It counts as a second upload; the verifier records the hash. A setting can reject a hash the same seller already has live. |
| **Quota restored by deleting** | `used` goes up when a ticket is reserved and is **never decreased** by story deletion. The delete trigger doesn't touch the counter. Deleting a story or replacing its video costs a new slot. |
| **Uploading without a ticket** | The storage policy denies it. Nightly cleanup deletes any quarantine object with no live ticket that's older than 1 hour. |
| **Endless failed verifications** | A file rejected by the verifier releases its slot (**decision O7**). Reservations are separately capped at 10 per day. |
| **Month boundary** | The period is set when the slot is reserved: `date_trunc('month', now() at time zone 'Africa/Lagos')`. |
| **Admin goodwill** | `admin_adjust_quota(user, period, delta, reason)` is written to the audit log. |
| **Settings changes** | New limits apply to new reservations. Existing videos are never removed because a limit changed. |

pgTAP tests cover every row of this table (see A8).

### A3. Founding membership (built in Phase 2)

**Settings** (admin-editable, every change logged): `founding_starts_at` = official launch date, `founding_ends_at` = start + 6 months. Once launch happens the window can be **extended but not shortened**.

**Who qualifies.** Every account created before `founding_ends_at` gets `profiles.founding_member_at` (set once, can't be changed by the user). That includes everyone who signed up before launch, because the window starts at launch. The badge shows publicly only on seller, professional and service-provider pages, because that's where it helps trust. Obvious test accounts can be unflagged by an admin, with a logged reason.

**Badge.** Permanent "Founding Seller / Founding Pro". It's only removed for a policy violation, and that's logged.

**Benefits** (all configurable; recommended defaults below, **decision O4**):

| Benefit | During window | After window |
|---|---|---|
| Free registration, storefront / Pro page / Creative Space, listings, enquiries, organic discovery, basic stats | ✓ | ✓ free forever |
| Video uploads | 5 per month (founding bonus) | Standard free allowance (3 per month) |
| Founding Boost credit: one free 7-day Product, Service or Profile Boost per month | ✓ (from Phase 3) | Ends. Unused credits expire at the window end, with a clear notice. |
| "Founding sellers" discovery strip on the homepage | ✓ | Removed |
| Founding badge | ✓ | ✓ permanent |

**Guarantees, enforced in code and stated in the Terms:**
- **No automatic billing is possible.** The system stores no cards and no Paystack recurring authorizations, and there's no subscription engine. Every payment is a one-off checkout the user starts.
- **No unexpected restrictions.** When the window ends, content made during it stays live: videos over the new quota, listings and pages are all kept. Only new uploads follow the new limit. Any future free-plan limit grandfathers existing content.
- **Notices.** An in-app banner and an email go out 30 days and 7 days before the window ends, plus an `/founding` explainer page.

### A4. Payment security (designed now, built in Phase 3)

**Where it runs** (**decision O3**, recommended). The Paystack secret key and Supabase service role live **only in Supabase Edge Functions**. Vercel holds no payment or service secrets. Functions:
- `payments-init`: called with the user's login token. It reads the price from `promotion_packages` on the server, never from the client.
- `paystack-webhook`
- `payments-reconcile`, run by cron
- `payments-refund`: admin only

**Tables:**
- `payments`: reference (UNIQUE, server-made), provider transaction id (UNIQUE), purpose + purpose id, `amount_kobo`, `currency = 'NGN'`, price snapshot, status, timestamps, failure reason, refunded amount
- `payment_events`: dedupe key (UNIQUE), raw payload, signature result, processed result
- `payment_state_history`
- `refunds`: provider refund id (UNIQUE)
- `payment_discrepancies`

**State machine** (transitions enforced by a trigger; anything else raises an error):

```
created → pending → succeeded → refund_pending → refunded | partially_refunded
                  ↘ failed        ↘ disputed → succeeded (won) | refunded (lost)
                  ↘ abandoned (no success after 24 h, confirmed by verify API)
Promotion: pending_payment → scheduled/active (ONLY via fulfil_payment) → expired
           active ⇄ paused (admin) · any → cancelled_refunded
```

**Activation path.** Only `fulfil_payment(reference, verified_payload)` activates anything. It can be called only by the service role and does the following in one transaction:
1. Locks the payment row (`FOR UPDATE`). If it's already `succeeded`, it does nothing and returns.
2. Requires the Paystack **verify API** result to be `success`.
3. Requires `amount == expected amount_kobo` and `currency == NGN`.
4. Requires the reference to match.
5. If all pass, marks the payment succeeded and activates the promotion. A mismatch is logged as a `payment_discrepancies` row for admin review, and nothing is activated.

**Webhook handling.**
1. Read the raw body and check HMAC-SHA512 against `x-paystack-signature` using the secret key, with a constant-time compare. Paystack signs every event this way [Fact].
2. Insert into `payment_events`; the unique dedupe key drops replays.
3. Call the verify API; don't trust the webhook body on its own. Then call `fulfil_payment`.
4. Return 200 quickly.

**The success redirect never activates anything.** `/payments/return` only reads the status from our database and shows "Confirming your payment…" while it polls. It can't call `fulfil_payment`.

**Reconciliation for missing or late webhooks:**
- Every 5 minutes, `payments-reconcile` calls the verify API for `pending` payments between 2 minutes and 24 hours old.
- After 24 hours, one final verification, then `abandoned`.
- Daily, compare against Paystack's transaction list. Anything that doesn't match (a payment we don't know about, a different amount) goes to `payment_discrepancies` and an admin alert.

**Refunds.**
1. An admin requests the refund with a reason; it's written to the audit log.
2. `payments-refund` calls Paystack `/refund` and the status becomes `refund_pending`. Money hasn't moved yet at this point.
3. `refund.processed` / `refund.failed` webhooks plus reconciliation set the final status.
4. The promotion stops when the refund is requested.

Paystack refunds draw from your Paystack balance, so a refund fails if the balance is too low [Fact]. The admin screen shows that error.

**Fees.** Local Paystack fees are 1.5% + ₦100. The ₦100 is waived under ₦2,500, and fees are capped at ₦2,000 [Fact]. So a ₦1,500 boost costs about ₦22.50 in fees. **Recommendation: absorb the fees.** Don't add a surcharge.

**Environments.** Test keys only on staging, live keys only in production, and separate webhook URLs.

### A5. Admin system (scalable; each module built only in its phase)

**Access, checked at three layers:**
1. `proxy.ts` blocks `/admin/*` for anyone who isn't an admin.
2. The admin layout checks on the server for role admin + 2FA (aal2).
3. Every write goes through an `admin_*` database function that checks `is_admin()` again.

**Permissions model** (**decision O9**): `admin_capabilities (user_id, capability)`. Capabilities: `settings.write`, `users.manage`, `content.moderate`, `payments.read`, `payments.refund`, `campaigns.review`, `analytics.read`, `audit.read`. For now you're the only super-admin; staff roles can be added later without a rewrite.

**Code structure.** Each module is `src/app/admin/<module>/` (screens) + `src/server/admin/<module>.ts` (queries/actions) + `admin_<module>_*` database functions. They share:
- a server-paginated data table
- a confirm-with-reason dialog for destructive actions
- an audit writer that extends the existing append-only `security_events` table [Fact] with `before` / `after` snapshots in `details`

**Settings.** A typed `platform_settings` table. Each key has a validated type and bounds (e.g. `video_max_seconds` 15–180). There's a `platform_settings_history` table (who, when, old value, new value, reason). Changes are made via `admin_update_setting()`.

| Module | Phase |
|---|---|
| Admin shell, access guard, audit-log viewer, **Settings** (founding window, quotas, limits) | 2 |
| **Users & sellers** (search, founding flag, quota adjustment, account status) and **Videos** (verification queue, moderation) | 2 |
| **Promotion packages**, **Payments**, **Promotions**, **Refunds**, **Reconciliation discrepancies** | 3 |
| **Business campaigns** review | 4 |
| Listings & ID-verification queues, reports, analytics dashboards, professionals | Later, when approved |

### A6. Storage & hosting projection

**Measured [Fact].** The one live video is 31 seconds at 720×1280 and **12.6 MB**, about 3.3 Mbps. That's the current browser setting (CRF 26, no bitrate cap).

| Setting | Average 35 s clip | 60 s maximum |
|---|---|---|
| Current (CRF 26, uncapped) | 14.3 MB | 24.4 MB |
| **Proposed:** CRF 26 with a 1.8 Mbps video cap + 128 kbps audio | **8.4 MB** | **14.5 MB** → proposed max upload **20 MB** |

**Assumptions [Assumption].**
- Active video sellers grow linearly.
- Each video gets most of its views in its first month, then a small tail.
- 60% of each file is watched on average.
- Half of the bandwidth is served from the CDN cache.

| Scenario | Video sellers at month 6 → 12 | Uploads per seller per month | Views per video (first month) |
|---|---|---|---|
| Low | 50 → 150 | 1.5 | 60 |
| Mid | 200 → 600 | 2 | 150 |
| High | 500 → 1,500 | 2.5 | 400 |

**Supabase plan limits [Fact]:**
- **Free:** 1 GB file storage, 5 GB egress, 5 GB cached egress.
- **Pro:** $25 per month. Includes 100 GB storage (then $0.0213/GB), 250 GB egress (then $0.09/GB) and 250 GB cached egress (then $0.03/GB). A spend cap is on by default.

**Projection with the proposed bitrate cap:**

| Scenario | Month 6 storage / egress per month | Month 12 storage / egress per month | Est. bill at month 6 | Est. bill at month 12 | Total, months 1–6 | Total, months 1–12 |
|---|---|---|---|---|---|---|
| Low | 2.2 GB / 27 GB | 10 GB / 92 GB | $25 | $25 | ~$150 | ~$300 |
| Mid | 12 GB / 346 GB | 55 GB / 1.2 TB | $25 | ~$64 | ~$150 | ~$410 |
| High | 36 GB / 2.9 TB | 172 GB / 9.5 TB | ~$166 | ~$566 | ~$548 | ~$2,890 |

Without the cap, the totals for months 1–12 are about $612 (Mid) and $4,924 (High).

**What this means:**
1. **Bandwidth, not storage, drives cost.** Storage stays inside Pro's 100 GB except in the High scenario.
2. **Even the Low scenario goes over the Free plan** by month 6: 2.2 GB of storage against 1 GB, and 27 GB of bandwidth against 10 GB.
3. **Upgrade to Pro at the Phase 2 go-live, not now.** Keep the spend cap on.
4. **Cost controls, built in Phase 2:**
   - Bitrate cap.
   - Cover image first, `preload="none"` and no autoplay in grids. This should cut wasted bandwidth further; the projection above does **not** count this saving.
   - A monthly usage query on the admin dashboard.
5. **Review trigger.** If bandwidth goes over about 1 TB a month (heading towards the High scenario), evaluate moving video delivery to a zero-egress store or video service. That would be a separate project with its own approval.

Model script: `docs/cost-model.py`. Change the assumptions there and re-run it.

### A7. Database recovery: reconcile without replaying (Phase 1b)

**Facts:**
- Production migration history has 15 entries, starting at `vendra_stories`, and its version numbers differ from the repo file names.
- Migrations 001–011 were run by hand in the SQL editor.
- Four production migrations have no file in the repo.
- The `011` file is missing.
- The `storage-cleanup` Edge Function's code isn't in the repo.
- Production contains 47 public tables, 156 functions (146 public, 10 private), 221 RLS policies, 14 storage policies and 4 cron jobs.

**Procedure** (production is only read until the last step):
1. **Change freeze.** From approval onwards, no DDL is typed into the production SQL editor. Every change goes through migrations (written as ADR-001).
2. **Capture production read-only.**
   - Schema-only dump of `public`, `private`, storage policies and bucket settings, cron jobs, extensions and grants. This uses `supabase db dump` run by you, and/or my read-only queries of `pg_get_functiondef` and `pg_policies`.
   - Download the Edge Function code (`supabase functions download storage-cleanup`).
   - **No data is copied.**
3. **Write the missing files** in the repo: `011` and the four production-only migrations, taken from the captured definitions. Nothing existing is edited.
4. **Rebuild staging from scratch.** Apply the repo migrations in order to an empty staging project.
5. **Compare.** Dump staging the same way, normalize both dumps, and diff them. The target is **zero differences**. Any difference is fixed by changing the *repo* until it matches production, never the other way round.
6. **Line up the history** (needs approval, **decision O2**). Rename the repo files to production's version numbers where they correspond. Then run `supabase migration repair --status applied <version>` for 001–011 and the reconstructed files. This **only inserts rows into the history table and runs no SQL** on production. Re-check `list_migrations` afterwards.
7. **Back up before every future production migration.** Take a `pg_dump` (schema + data), stored privately and off-repo.

**Test data.** Staging uses **synthetic seed data only**, from `supabase/seed.sql` plus a generator script: invented Nigerian-style names and shops, placeholder images and small generated test videos. No production rows are copied, and the `id-documents` bucket is never copied. If production-shaped data is ever needed, it goes through an anonymizer first: emails hashed to `user-<n>@example.test`, names, phones and addresses replaced, free text scrubbed, files excluded.

### A8. Testing & deployment (set up in Phase 1b, used from Phase 2 onwards)

| Environment | Database | Frontend | Payment keys |
|---|---|---|---|
| CI (each push) | Temporary Supabase started in GitHub Actions (`supabase start`), migrations from scratch | Build only | none |
| **Staging** | Second Supabase project, synthetic data | Vercel **Preview** deployments | Paystack **test** keys |
| Production | Current `PURPLE VENDRA` project | Vercel Production | Paystack live keys |

**Pipeline:**
1. **Feature branch → PR.** CI runs lint, type check, build, `npm audit`, **Vitest** unit tests and **pgTAP** database tests on a temporary database built from migrations.
2. **Stage it.** The `deploy-staging-db` GitHub Action (manual trigger) runs `supabase db push` to staging. The Vercel preview uses the staging keys.
3. **Test on staging.** **Playwright** end-to-end tests run against the preview + staging, at a mobile size (390 px) and desktop. 2FA sign-in works with a seeded TOTP secret.
4. **Approve.** You approve in the PR. The report lists the files, migrations, tests and known issues.
5. **Production migration.** The `deploy-production-db` Action runs behind a GitHub **environment protection rule** (needs your approval). It **refuses to run unless staging passed for the same commit**. It takes a `pg_dump` first, then runs `supabase db push`.
6. **Production frontend.** Merge to `main` and Vercel deploys. Migrations are **expand → deploy code → contract**: the new code works with the old schema and the old code with the new schema, so the order is safe.
7. **Rollback.** Vercel instant rollback for the frontend. Every migration includes a written and **staging-tested** down script, or explains why it's forward-only and has the backup as the fallback.

**Test coverage targets:**
- pgTAP:
  - existing critical rules (sellers need 2FA to post, contact-details guard, self-promotion blocked, RLS on every table)
  - every A2 threat row
  - every A4 state transition, plus duplicate webhook, wrong amount and wrong currency
- Playwright: the existing journeys listed in audit §7, so current behaviour is protected, plus new features.

### A9. Record of decisions and database changes (starts in Phase 1b)

- `docs/decisions/ADR-NNN-title.md`: one per decision (context, options, choice, consequences, date, who approved).
- `docs/DB-CHANGELOG.md`: one entry per migration. What it changes, why, risk, rollback, staging test result, production applied date and commit.
- `PROJECT_STATUS.md`: updated at every phase gate.

---

## Part B — Phase 1b implementation plan (Foundation)

**Goal.** Make the repo the single source of truth for the database, stand up staging, and put the test and deployment pipeline in place, all **without changing production behaviour**.

### Workstreams, dependencies, deliverables, estimates

| # | Workstream | Depends on | Deliverables | Estimate |
|---|---|---|---|---|
| W1 | Change control & records | Approval | ADR-001 (change freeze), ADR template, `DB-CHANGELOG.md`, updated `PROJECT_STATUS.md` | 0.5 d |
| W2 | Capture the production schema (read-only) | O1, O2 | Normalized schema dump, list of functions/policies/cron/buckets/grants, `storage-cleanup` code in `supabase/functions/` | 1 d |
| W3 | Reconstruct missing migrations | W2 | `011` + the 4 production-only migrations as files; mapping of repo files ↔ production versions | 1–1.5 d |
| W4 | Staging environment | O1 + your account actions | Staging Supabase project, Vercel Preview env vars, repo `config.toml`, a written env matrix | 0.5 d (+ your time) |
| W5 | Clean rebuild + schema diff | W3, W4 | Staging built from migrations; diff report showing **zero differences** from production | 1 d |
| W6 | Synthetic seed + anonymizer | W5 | `seed.sql` + generator (buyers, sellers, professionals, service providers, listings, stories, requests, messages); anonymizer script with tests | 1 d |
| W7 | Test harness | W5, W6 | pgTAP suite for **existing** critical rules; Vitest set up with first tests; Playwright smoke tests for the existing journeys, including 2FA | 2 d |
| W8 | CI/CD pipeline | W7 | Updated `ci.yml` (unit + DB tests); `deploy-staging-db` and gated `deploy-production-db` workflows; rollback runbook | 1 d |
| W9 | Pipeline dry run with a safe change | W8, O2 | First real migration through the full pipeline: revoke RPC execute on the trigger-only `limit_saves()`. You'll also turn on leaked-password protection in the dashboard. | 0.5 d |
| W10 | De-risk the video verifier (staging only) | W4 | Edge Function prototype that parses MP4 duration and codec from the start of the file, tested against 10+ phone-recorded samples | 1 d |
| W11 | Production history alignment | W5 = zero diff, O2 | `migration repair` rows added; `list_migrations` matches the repo | 0.25 d |

**Total: about 9–11 working days** (W10 can run in parallel; your actions are on top). That's up from 2–3 days, because recovery now includes the full schema comparison, the gated pipeline and a working test suite rather than just exporting files.

**Order:** W1 → W2 → W3 → (W4 in parallel) → W5 → W6 → W7 → W8 → W9 → W11. W10 can run in parallel once W4 is done.

### Phase 1b risks

| Risk | Mitigation |
|---|---|
| The production diff shows more drift than expected | Each difference is recorded; the repo is fixed to match production. If the gap is large, I stop and report before W11. |
| The schema dump needs the production DB password | You run one CLI command locally, or I use only read-only catalog queries through the connected Supabase tool. |
| Supabase Free allows 2 active projects, and free projects pause after a week of inactivity [Fact] | Staging takes the second slot; Crop AI is currently paused [Fact]. CI starts its own temporary DB, so a paused staging project only delays the Playwright tests. |
| 2FA makes the end-to-end tests harder | A seeded TOTP secret for staging test accounts only. |
| GitHub Actions run time | The repo is currently **public** [Fact], so standard runners are free. If you make it private (worth considering, see note), DB tests take about 3–5 minutes per run against the free private-repo allowance. |
| `migration repair` writes to production | It writes history rows only. It runs only after a zero diff on staging and needs your approval. Production is backed up first. |

### Phase 1b acceptance criteria

1. A brand-new empty Supabase project built **only from the repo** matches production's schema with **zero differences** (tables, columns, types, functions, triggers, RLS and storage policies, grants, buckets, cron jobs, extensions). The diff report is committed.
2. Production migration history lists every repo migration. **No production object was created, changed or dropped** in Phase 1b apart from: the W9 hygiene migration (sent through the pipeline, with your approval) and the history rows from W11.
3. The staging site (Vercel Preview + staging DB) runs with synthetic data. No production personal data exists in staging.
4. CI fails the PR if any lint, type, unit or pgTAP test fails. pgTAP covers the existing critical database rules, with at least 40 assertions.
5. The Playwright smoke suite passes on staging at mobile and desktop sizes: browse → search → listing → shop → `/pro` → stories feed → sign up → 2FA → seller hub → create listing → message.
6. The production DB workflow can't run without your approval and a green staging run for the same commit. This has been shown with the W9 dry run.
7. The video-verifier prototype correctly reports duration and codec, within ±0.5 s, for every test sample. It rejects a renamed non-video file and an over-length file.
8. ADR-001, `DB-CHANGELOG.md` and `PROJECT_STATUS.md` are up to date; the rollback runbook is written.
9. Existing site behaviour is unchanged. The Playwright suite passes against production in read-only browse mode.

### Updated estimates for later phases (after Phase 1b)

| Phase | Scope change from v1.0 | Estimate |
|---|---|---|
| 2 Founding Free Plan + video | + quarantine pipeline, ticket system, admin shell, Settings / Users / Videos modules, founding notices | 8–11 d |
| 3 Featured Promotions | + Edge Function payments, reconciliation, refunds, 5 admin modules, Founding Boost credits | 10–14 d |
| 4 Business Campaigns | Unchanged scope, reuses payments and admin | 7–10 d |

---

## Part C — Decisions that need your approval

**Needed before Phase 1b starts**

| # | Decision | Recommendation |
|---|---|---|
| O1 | Staging = a second **free** Supabase project (you create it; I configure it). Alternative: Supabase Pro branching. | Free project now. |
| O2 | (a) I may run **read-only** catalog queries on production to capture the schema. (b) After a zero diff, I may add **history rows only** with `migration repair`. (c) The W9 hygiene migration goes to production through the new gated pipeline. | Approve all three; each is confirmed with you again at the time. |
| O3 | Payments run in **Supabase Edge Functions**, so Vercel holds no service or payment secrets, with **Paystack** as the provider. (The alternative is Next.js routes with a service key in Vercel.) | Edge Functions + Paystack. Affects how staging is set up now, built in Phase 3. |

**Needed before Phase 2**

| # | Decision | Recommendation |
|---|---|---|
| O4 | Founding package: who qualifies (all accounts before window end, including pre-launch), permanent badge, benefits (5 videos/month during window, monthly Founding Boost credit from Phase 3, homepage strip) | As in A3 |
| O5 | Official launch date (starts the 6-month window) | You set it; it can be entered later in Settings |
| O6 | Video limits: 3/month free (5 founding), 60 s, **20 MB** max, **1.8 Mbps** bitrate cap; replacing a video counts as an upload; the current "10/day" rule for existing sellers is replaced | Approve |
| O7 | A file that **fails verification** releases its slot (reservations are capped at 10/day separately). Deleting a verified video never does. | Approve |
| O8 | Videos publish automatically after technical verification; the manual pre-review switch stays off unless abuse appears | Approve |
| O9 | Admin: you as the only super-admin now, with the capability table ready for staff roles later | Approve |
| O10 | Upgrade to **Supabase Pro** ($25/month, spend cap on) at Phase 2 go-live | Approve timing |

**Needed before Phase 3**

| # | Decision | Recommendation |
|---|---|---|
| O11 | Existing `story_campaigns` (budget-based): stop new ones and replace with the fixed 7-day Video Promotion package (0 existing campaigns [Fact]) | Approve |
| O12 | Refund & cancellation policy for promotions (e.g. full refund before the start; none once delivery has begun except for our error) and dispute handling | Your business call; I'll draft the wording |
| O13 | Absorb Paystack fees (about ₦22.50 on a ₦1,500 boost) instead of adding a surcharge | Absorb |
