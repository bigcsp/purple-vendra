# Purple Shop — Technical Plan & Phase 1b Implementation Plan

**Version:** 1.2 · 16 Nov 2026 · **Status:** awaiting formal approval of Phase 1b. No application code or production database changes have been made.
**Companion docs:** `docs/PHASE-1-AUDIT.md` (findings) · `docs/MIGRATION-MAPPING.md` (repo ↔ production) · `docs/cost-model.py` (hosting projection)
**Labels:** **[Fact]** = verified in code, the live database or the provider's documentation. **[Assumption]** = an estimate.

## What changed from v1.1

| # | Your requirement | Where it's answered |
|---|---|---|
| 1 | Quota accounting: `reserved` vs `used`, one reservation for video + cover | A2 (rewritten) |
| 2 | Full migration mapping before any renaming or repair; documented environment differences; no production history change without separate approval | A7, `MIGRATION-MAPPING.md`, checkpoint C1, approval P1 |
| 3 | Exact Storage API for private → public, demonstrated on staging, with a copy–verify–delete fallback | A1.1, W10 |
| 4 | Cost formulas, cached vs uncached egress, reproducible, verified prices kept separate | A6, `cost-model.py` |
| 5 | W9 is now **staging-only**, with effects and rollback; production needs separate approval | W9, P2, P3 |
| 6 | Promotions for every kind of seller, each with a destination and a measurable action | A10 (new) |
| 7 | Admin recovery | A11 (new), W11 |

Corrections from v1.1:
- **The "four production-only migrations" aren't missing SQL.** Their content is already folded into repo files 014, 016 and 020. The genuinely missing file is **011**, and without it a clean rebuild fails at 012.
- **Leaked-password protection is available only on Pro and above** [Fact], so it can't be switched on in a free staging project.

---

## Part A — Designs (Phase 1b builds the foundation; features are built in the phase shown)

### A1. Video security: private quarantine, then publish (Phase 2)

The flow from v1.1 stands: reserve a ticket → upload to the private `story-uploads` bucket → submit → server verification → publish or reject. Nobody can view a file before it's verified. Only the service role (inside the verifier Edge Function) can write to the public `story-media` bucket. The values the server measures replace whatever the browser reported. A database trigger blocks `published` until the media is verified.

#### A1.1 Storage operation for private → public (verified, then demonstrated in W10)

- **Primary operation [Fact].** The app's installed client (`@supabase/storage-js` 2.119.0) implements `storage.from(src).move(from, to, { destinationBucket })`. It sends `POST /object/move` with `bucketId`, `sourceKey`, `destinationKey` and `destinationBucket`; I checked the package source. Supabase documents cross-bucket moves with this method.
- **Known history [Fact].** A Supabase discussion (#26624) reported cross-bucket copy/move changing only the source bucket. The reply says it was fixed in storage-js PR #197. No version is given, so **this has to be shown working, not assumed.**
- **What W10 demonstrates on staging** (service role, private → public bucket, with a recorded result):
  1. The object appears at the destination and is gone from the source.
  2. Size and content hash are unchanged, and metadata (`mimetype`, `size`) is kept.
  3. The public URL plays the video; the private path no longer resolves.
  4. Whether the destination bucket's `file_size_limit` / `allowed_mime_types` are applied on move.
  5. Moving to a path that already exists fails and doesn't overwrite.
- **Fallback, used if any check fails:** copy → verify → delete, run as a resumable job keyed on the ticket:
  1. `copy(from, to, { destinationBucket: 'story-media' })` (the same client supports `destinationBucket` on copy). Ticket → `publishing`.
  2. **Verify the destination:** it exists, `size` matches the source, and the SHA-256 of the destination equals the hash the verifier already recorded (re-download ≤ 20 MB).
  3. Only after that, point the story at the destination path and set status.
  4. Delete the source. If the delete fails, the source is queued in `storage_deletion_queue`. The quarantine bucket is private, so a leftover copy is never public.
  5. Every step is idempotent. A retry after a crash continues from the ticket status without double-publishing.
- Whichever method is used is written up as an ADR with the staging evidence.

### A2. Upload quota accounting (Phase 2; all enforcement in the database)

**One reservation covers one video and its cover.** A ticket holds two server-generated paths: `video_path` (required) and `cover_path` (optional). Each path can be uploaded once. The pair is verified together and published together.

**Counter row:** `media_quota_usage (user_id, period, reserved int ≥ 0, used int ≥ 0, bonus int default 0)`.
- `quota(user, period) = base_allowance + founding_bonus (if eligible) + bonus`. All of these come from settings or admin adjustments.
- `bonus` holds admin goodwill adjustments, so `used` is never edited by hand.

**Transitions.** Each one is a single `UPDATE … WHERE status = <expected> RETURNING`, run in the same transaction as the counter change, so **each ticket can change the counters at most once**:

| Event | Ticket status | `reserved` | `used` | Notes |
|---|---|---|---|---|
| Reserve | — → `reserved` | **+1** | 0 | Allowed only if `used + reserved + 1 ≤ quota`, the user has no other open ticket, and has made fewer than 10 reservations today. The counter row is locked with `SELECT … FOR UPDATE`, so simultaneous requests run one at a time. |
| Upload file(s) | stays `reserved` | 0 | 0 | The storage policy checks path + status + `expires_at`. There's no update/upsert policy. |
| Submit | `reserved` → `uploaded` | 0 | 0 | Idempotent (a repeat returns the same story). Queues verification. |
| Verification starts | `uploaded` → `verifying` | 0 | 0 | |
| **Verification passes** | `verifying` → `verified` | **−1** | **+1** | Then publish (A1.1). |
| **Verification fails** (bad file, or technical failure after 3 tries) | `verifying` → `rejected` | **−1** | 0 | The file is deleted and nothing is published. |
| Reservation expires (30 min, configurable) or is cancelled | `reserved` → `expired` / `cancelled` | **−1** | 0 | Cron sweep; any stray file is queued for deletion. |
| **Verified story deleted** | (ticket stays `verified`) | 0 | **0** | **Never restores quota.** The delete trigger has no access to the counters. |
| Replace a video | new ticket | +1 → (−1, +1) | | Costs a slot, just like a new upload. |
| Cover-only change | separate `cover_only` ticket | not counted | not counted | Still quarantined and verified; limited to 10/day. |
| Admin goodwill | — | 0 | 0 | `bonus += n` via `admin_adjust_quota(user, period, n, reason)`; logged. |

**Edge cases:**
- A ticket reserved in January and verified in February counts against **January**, because the period is stored on the ticket.
- If an admin lowers the quota mid-month, existing videos stay. New reservations are refused until the next reset.
- Database checks enforce `reserved ≥ 0` and `used ≥ 0`. A nightly consistency job compares counters with ticket totals and raises an admin flag if they differ, instead of silently fixing them.
- pgTAP covers every row of this table, plus concurrent reservations from two sessions.

### A3. Founding membership (Phase 2): unchanged from v1.1

Founding status comes from account creation before the window ends (this includes everyone who joined before launch). The badge is permanent. Temporary benefits are configurable, and the basic marketplace stays free for good. No billing is possible because no cards or recurring authorizations are stored. Content is never removed when the window ends. Notices go out 30 and 7 days before the end.

### A4. Payment security (Phase 3): unchanged from v1.1

Activation happens only through `fulfil_payment()`, which runs as the service role after the Paystack verify API confirms the payment and the amount and currency match. Webhooks are checked with HMAC-SHA512 and deduplicated. Reconciliation runs every 5 minutes and daily. Refunds go through a refund-pending state. The success redirect page only reads status. **Nothing in A4 is built in Phase 1b.**

### A5. Admin system: unchanged from v1.1, plus A11 recovery

### A6. Storage & hosting cost model

**Verified provider pricing** (Supabase pricing page, checked 16 Nov 2026) [Fact]:

| Item | Free | Pro |
|---|---|---|
| Base | $0 | $25/month (includes $10 compute credit = one Micro instance) |
| File storage | 1 GB | 100 GB included, then $0.0213/GB |
| Egress (uncached) | 5 GB | 250 GB included, then $0.09/GB |
| Cached egress | 5 GB | 250 GB included, then $0.03/GB |

**Measured** [Fact]: the live video is 12.63 MB for 31.0 s, which is 0.4074 MB/s with the current browser encode.

**Assumptions** [Assumption], all editable at the top of `cost-model.py`:
- average clip 35 s (maximum 60 s)
- bitrate cap 1.8 Mbps video + 0.128 Mbps audio (= 0.2410 MB/s)
- 60% of each file delivered per view
- **50% of delivered bytes served from the CDN cache**
- linear seller growth, no deletions, storage billed on the library size at month end
- scenario parameters as in v1.1

**Formulas** (copied from `project()` in `cost-model.py`):

```
MB/s (capped)   = (1.8 + 0.128) / 8 = 0.2410        MB/s (current) = 12.63 / 31.0 = 0.4074
sellers(m)      = m ≤ 6 ? s6·m/6 : s6 + (s12 − s6)·(m − 6)/6
new_videos(m)   = sellers(m) · uploads_per_seller
library(m)      = library(m−1) + new_videos(m)
file_MB         = avg_seconds · MB/s + thumb_MB
storage_GB(m)   = library(m) · file_MB / 1024
views(m)        = new_videos(m) · first_month_views + library(m−1) · tail_views
delivered_GB(m) = views(m) · avg_seconds · MB/s · watch_fraction / 1024
cached_GB(m)    = delivered_GB(m) · cached_share
uncached_GB(m)  = delivered_GB(m) · (1 − cached_share)
pro_bill(m)     = 25 + max(0, storage_GB − 100)·0.0213 + max(0, uncached_GB − 250)·0.09 + max(0, cached_GB − 250)·0.03
```

**Output** of `python3 docs/cost-model.py`, proposed bitrate cap:

| Scenario | Month | Videos | Storage GB | Uncached GB/mo | Cached GB/mo | Pro bill $/mo | Total months 1–6 | Total months 1–12 |
|---|---|---|---|---|---|---|---|---|
| Low | 6 | 262 | 2.2 | 13.4 | 13.4 | 25.00 | $150 | $300 |
| Low | 12 | 1,238 | 10.3 | 45.9 | 45.9 | 25.00 | | |
| Mid | 6 | 1,400 | 11.6 | 173.0 | 173.0 | 25.00 | $150 | $410 |
| Mid | 12 | 6,600 | 54.9 | 578.3 | 578.3 | 64.39 | | |
| High | 6 | 4,375 | 36.4 | 1,428.7 | 1,428.7 | 166.44 | $548 | $2,890 |
| High | 12 | 20,625 | 171.5 | 4,749.3 | 4,749.3 | 566.44 | | |

**Worked check, Mid month 12:**
- Uncached overage: (578.3 − 250) × 0.09 = $29.55
- Cached overage: (578.3 − 250) × 0.03 = $9.85
- Storage: 54.9 GB, under 100 GB, so $0
- Total: $25 + $29.55 + $9.85 = **$64.40**. The script rounds to $64.39 because it doesn't round intermediate values.

**Uncapped (current encode):** months 1–12 totals are Low $300, Mid $612, High $4,924. The free plan is exceeded from month 2–3 in Low and from month 1 in Mid and High.

**Sensitivity:**
- The cache share only moves bandwidth between $0.09 and $0.03 per GB; it doesn't change the total delivered.
- If the cache share were 0%, Mid month 12 would be $25 + (1,156.5 − 250) × 0.09 = **$106.59**.
- Totals assume Pro from month 1 of video go-live.
- **Recommendation unchanged:** upgrade to Pro when Phase 2 goes live (O10), with the spend cap on.

### A7. Database recovery

The procedure from v1.1 stands, with these changes:
- The **complete mapping** is in `docs/MIGRATION-MAPPING.md`, including the 1:2 and 1:3 cases and the expected environment-specific differences.
- **Checkpoint C1:** I present the final content-level mapping, the staging diff report and the allowed-differences list. **You review them before any repo file is renamed or split.**
- **Production history is never changed in Phase 1b without separate approval (P1).** Even then, Option A only *adds* 11 rows and never edits existing ones.

### A8. Testing & deployment: unchanged from v1.1

### A9. Records: unchanged from v1.1

ADRs, `DB-CHANGELOG.md` and `PROJECT_STATUS.md`.

### A10. Promotion architecture for the whole marketplace (designed now, built in Phase 3)

**Model:**
- `promotion_target_types` is a registry, so adding a new type is configuration plus one eligibility function, not a rewrite. Each row holds: code, target table, eligibility function, destination route, allowed placements, primary action, secondary actions.
- `promotion_packages` link a target type to a price and duration (admin-configurable).
- `promotions` store `target_type` + `target_id`. Eligibility is checked **in the database**: the seller owns the target, and it's live, approved, published or public.
- `promotion_events (promotion_id, placement, event_type, at)` are anonymous, like the existing `story_events`.
- Enquiries from a promotion are tagged by passing `promotion_id` to `start_conversation`.

| Promotion type | Who it serves | Target (existing) | Destination | Primary measurable action | Secondary actions |
|---|---|---|---|---|---|
| Product Boost | Product sellers, makers | `listings` type `product` | `/l/[id]` | Listing view from a sponsored placement | Save, add to cart, enquiry; orders once checkout exists |
| Service Boost | Freelancers, home-service pros | `listings` type `service` | `/l/[id]` | Enquiry (message) or quote/booking request | Listing view, save |
| Talent Boost | Performers, creatives for hire | `listings` type `talent` | `/l/[id]` | Enquiry | Listing view, save |
| Store Spotlight | Shop owners | Seller shop (`profiles`, role seller) | `/shop/[username]` | Shop visit | Follow, listing click from shop, enquiry |
| Professional Profile Boost | Freelancers, professionals | `profiles` with `pro_mode = professional`, public | `/pro/[username]` | Profile view | Enquiry, external portfolio-link click (tracked redirect), share |
| Creative Portfolio Boost | Artists, designers, photographers | `profiles` with `pro_mode = creative_space`, public | `/pro/[username]` | Profile view | Project/entry click, enquiry, share |
| Video Promotion | Anyone with a published story | `story_videos` (verified, published) | Story player (`/stories`, shop page) | Video view (counted after 3 s of play) | Completion, product tap, shop visit, add to cart, enquiry |

**Placements:**
- search results, category pages, homepage spotlight, stories feed, and a "related" strip on listing pages
- each placement only accepts compatible target types
- each is labelled **Sponsored**, with a frequency cap, and organic results are never removed

**Reports to sellers** show only events that were actually recorded, as counts, never estimates.

**Phase 3 prerequisite** (found in the audit): `listing_events` is never written by the app today, so listing-view tracking has to be added before Product, Service or Talent boosts can report results.

### A11. Admin recovery: never permanently locked out (runbook in Phase 1b, UI in Phase 2)

**Facts:** Supabase Auth has no recovery codes, but a user can enroll up to 10 TOTP factors. Supabase recommends registering a backup TOTP factor in case the main one is lost.

| Layer | What it protects against | When |
|---|---|---|
| **1. Backup TOTP factor** on the super-admin account, on a second device or offline authenticator kept in a safe place | Lost or broken phone | Runbook in 1b. You can enroll it once Phase 2 adds a "second authenticator" option to `/account/security`. |
| **2. Break-glass admin account** (**decision O14**): separate email, separate authenticator, unused day to day, credentials stored offline, and every sign-in raises an audit event | Main admin account unusable (email lost, account compromised) | Created in Phase 2 |
| **3. Root recovery through the Supabase dashboard**: the project owner (Supabase org account, itself with 2FA) removes the lost factor (Auth Admin API `mfa.deleteFactor`, or SQL on `auth.mfa_factors` as a fallback), signs out all of that user's sessions, writes an `admin_recovery` entry to `security_events`, and the admin re-enrolls | Every in-app method lost | **Runbook written and rehearsed on staging in Phase 1b (W11)** |
| **4. Account hygiene, done by you** | Losing the root itself | 2FA on Supabase, GitHub, Vercel and the admin email; their recovery codes stored offline; optionally a second trusted Supabase org member (**O14**) |

**Guardrails** (Phase 2 database rules):
- The **last remaining admin can't be demoted, suspended or deleted**.
- Role changes happen only through an audited `admin_set_role()` function.
- **No hidden backdoor** in the app: no secret URLs and no "master" codes.
- Recovery always goes through the Supabase owner account, which sits outside the app.

---

## Part B — Final Phase 1b checklist

**Scope rule.** Foundation work only: records, schema capture, migration reconstruction, staging, tests, the deployment pipeline, a staging-only verifier and move demo, and the recovery runbook. **Phase 2, payments, promotion packages and business campaigns don't start** until Phase 1b is completed, tested, presented and approved by you.

**No application code changes** in Phase 1b. New files go only under `docs/`, `supabase/` (migrations for staging, functions, tests, seed), `tests/` and `.github/`. Production stays live and unchanged throughout. Any production change happens only through approvals P1–P3.

### B1. Work to be performed

| # | Work | Depends on | Estimate |
|---|---|---|---|
| W1 | Change control: ADR template, ADR-001 (change freeze on hand-run production DDL), `DB-CHANGELOG.md`, `PROJECT_STATUS.md` | Phase 1b approval | 0.5 d |
| W2 | Capture the production schema **read-only**: catalog queries (`pg_get_functiondef`, `pg_policies`, tables/columns/types/triggers/grants, buckets, cron jobs, extensions) plus the Edge Function code, using the connected Supabase tool. **No data copied.** | O2a | 1 d |
| W3 | Content-level mapping: compare each repo file with production's recorded SQL and live definitions; reconstruct **011**; add `supabase/functions/storage-cleanup/` → **checkpoint C1 (your review)** before any rename or split | W2 | 1.5 d |
| W4 | Staging environment set up: `supabase/config.toml`, environment matrix, Vercel Preview configured against staging | O1 + your actions (B2) | 0.5 d |
| W5 | Clean rebuild of staging from the repo, then a normalized schema diff against production. Target: zero unexplained differences; allowed differences documented. | W3 (after C1), W4 | 1.5 d |
| W6 | Synthetic seed (buyers, product sellers, freelancers, service pros, creatives, listings of every type, stories, requests, messages) + anonymizer script with tests | W5 | 1 d |
| W7 | Test harness: pgTAP (≥ 40 assertions on existing critical rules), Vitest set up, Playwright smoke tests of existing journeys including 2FA (mobile + desktop) | W5, W6 | 2 d |
| W8 | CI/CD: `ci.yml` adds unit + DB tests; `deploy-staging-db`; `deploy-production-db`, gated on your approval + green staging for the same commit + `pg_dump` first; rollback runbook | W7 | 1 d |
| W9 | **Staging-only** trial of the two hygiene changes, with an effects + rollback report (see B5) | W5, W7 | 0.5 d |
| W10 | Staging prototypes: (a) the verifier Edge Function parses MP4 duration/codec from the start of the file; (b) the **private → public move demonstration** in A1.1, plus the copy–verify–delete fallback | W4 | 1.5 d |
| W11 | Admin recovery runbook + **rehearsal on staging**: lose a factor → root recovery → re-enroll → audit entry present | W4 | 0.5 d |
| W12 | Phase 1b report: what was done, evidence, test results, known issues, approvals still pending | All | 0.5 d |

**Estimate: 10–12 working days**, plus the time for your actions and checkpoint C1. W10 and W11 can run alongside W5–W8.

### B2. Work that needs your direct involvement

1. **Approve Phase 1b** and decisions **O1–O3**.
2. **Create the staging Supabase project** (free plan, region eu-west-2 to match production). Name it `purple-shop-staging`. It will appear in the connected Supabase organization.
3. **Vercel:** add Preview environment variables pointing to staging. I'll provide the exact list.
4. **GitHub:**
   - Create environments `staging` and `production`, with **yourself as the required reviewer on `production`**.
   - Add the secrets I list (Supabase access token, project refs, DB passwords). You enter them; I never see the values.
5. **Phone video samples:** 4–6 short clips recorded on different phones, including an iPhone (HEVC) and an Android. I'll generate the rest synthetically.
6. **Account security (A11, layer 4):**
   - 2FA on Supabase, GitHub, Vercel and the admin email.
   - Recovery codes stored offline.
   - Decide on O14.
7. **Checkpoint C1:** review the final migration mapping and diff report.
8. **Phase 1b sign-off** at W12, and separate decisions on P1–P3.

### B3. Deliverables

- `docs/decisions/ADR-001…` (change freeze, migration-alignment option, storage-move method), `docs/DB-CHANGELOG.md`, updated `PROJECT_STATUS.md`
- `docs/MIGRATION-MAPPING.md` (final, content-level) + `docs/SCHEMA-DIFF-REPORT.md` (staging vs production, allowed differences listed)
- `supabase/migrations/…011_privacy_data_rights.sql` (reconstructed), the repo layout agreed at C1, `supabase/functions/storage-cleanup/`, `supabase/config.toml`, `supabase/seed.sql` + generator, anonymizer
- `supabase/tests/*.sql` (pgTAP), `tests/unit/*` (Vitest), `tests/e2e/*` (Playwright)
- `.github/workflows/ci.yml` (extended), `deploy-staging-db.yml`, `deploy-production-db.yml`
- `docs/runbooks/rollback.md`, `docs/runbooks/admin-recovery.md`, `docs/ENVIRONMENTS.md`
- `docs/W9-HYGIENE-TRIAL.md` (staging results, effects, rollback), `docs/W10-VERIFIER-AND-MOVE.md` (evidence)
- `docs/PHASE-1B-REPORT.md`

### B4. Acceptance criteria

1. **Rebuild:** a new empty project built only from the repo matches production's schema, with every difference either zero or listed in the allowed-differences table with a reason. The diff report is committed.
2. **Mapping:** every production history row maps to a repo file, and every repo file maps to a history row or is explicitly marked "applied by hand (P1)". You reviewed it at C1 **before** any rename or split.
3. **Production unchanged:** a re-capture of the production schema at the end of Phase 1b is **identical** to the W2 capture, apart from anything you approved separately under P1–P3.
4. **Staging** runs on synthetic data only; no production personal data or files are present.
5. **CI** blocks a PR on any lint, type, unit or pgTAP failure; pgTAP has ≥ 40 assertions on existing rules.
6. **Playwright smoke tests** pass on staging at 390 px and desktop for: browse → search → listing → shop → `/pro` → stories → sign up → 2FA → seller hub → create listing → message. They also pass against production in **read-only browse mode** (no sign-ups, no writes).
7. **Deployment gate:** `deploy-production-db` refuses to run without your approval and a green staging run for the same commit. Shown with a no-op dry run against staging settings; it is **not** run against production.
8. **W9:** both hygiene changes trialled on staging where the plan allows (see B5), with the observed effects and a tested rollback.
9. **W10:**
   - The verifier reads duration within ±0.5 s and the correct codec on every sample.
   - It rejects a renamed non-video, an over-length clip and an oversized file.
   - The move (or fallback) passes all five checks in A1.1, with evidence recorded.
10. **W11:** admin-recovery rehearsal completed on staging; the audit entry is present; the runbook is followed exactly as written.
11. **Records:** ADRs, DB changelog, `PROJECT_STATUS.md` and runbooks are up to date. Phase 1b report delivered.

### B5. Production actions that need separate approval

None of these runs as part of the Phase 1b approval. Each is presented with evidence, effect and rollback, and runs only after your explicit "approved" for that item.

| # | Action | Staging evidence first | Effect on production | Rollback |
|---|---|---|---|---|
| **P1** | Add history rows for repo files 001–011 (`migration repair --status applied`), only after C1 and a clean diff | Same command run on a staging copy, then `list_migrations` compared | Writes 11 rows to `supabase_migrations.schema_migrations`. **No schema change, no SQL run.** | `migration repair --status reverted <version>` removes exactly those rows. A `pg_dump` is taken first. |
| **P2** | `revoke execute on function public.limit_saves() from public, anon, authenticated` (through the gated pipeline) | Staging: saving and unsaving items still works (Postgres checks EXECUTE on a trigger function when the trigger is created, not when it fires; the repo already revokes other trigger functions the same way and those features work [Fact]); calling `rpc/limit_saves` now returns permission denied; Security Advisor warning cleared | Removes one Security Advisor warning. Nobody can call this trigger function directly through the API any more. | `grant execute on function public.limit_saves() to anon, authenticated;` |
| **P3** | Turn on leaked-password protection | **Can't be switched on in a free staging project**: it needs Pro or above [Fact]. On staging I'll instead test that the sign-up and password-change forms show a clear message when Supabase rejects a weak password (simulated error). | New sign-ups and password changes using a password known from data breaches are rejected. Existing users aren't affected until they change their password. | Turn the setting off in the dashboard. |
| **P4** | *(Not Phase 1b; noted for Phase 2)* Add a shared-secret header to the `storage-cleanup` call | Staging | Stops outsiders triggering the cleanup function | Re-deploy the previous version |

P3 depends on the Pro upgrade (**O10**). I recommend doing both together at Phase 2 go-live, unless you choose to upgrade earlier.

---

## Part C — Decisions

**Needed to start Phase 1b:**

| # | Decision | Recommendation |
|---|---|---|
| O1 | Staging = second **free** Supabase project | Approve |
| O2a | Read-only production catalog access for schema capture (no data, no changes) | Approve |
| O3 | Payments will live in Supabase Edge Functions, with Paystack. This affects how secrets are laid out in staging now; nothing is built until Phase 3. | Approve |

**Needed during Phase 1b:**
- **C1:** review of the final migration mapping before any rename or split.
- **O14:** break-glass second admin account (recommended) and whether to add a second trusted Supabase org member (your call).
- **O15:** make the GitHub repo private (recommended; currently public [Fact]).

**Separate production approvals:** P1, P2, P3 (Part B5).

**Before Phase 2 and Phase 3:** O4–O13, unchanged from v1.1.
