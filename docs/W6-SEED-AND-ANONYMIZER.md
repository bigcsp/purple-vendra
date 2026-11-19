# W6: Synthetic seed and anonymizer

**Status:** **accepted by the owner, 19 Nov 2026.** Seed generator **w6-2**; staging now holds the w6-2 seed (replaced 19 Nov, see §5).
**Scope:** staging and local databases only. Production is never written to; it was only read for counts and catalog checks.

| Deliverable | File |
|---|---|
| Seed generator (deterministic) | `supabase/tools/seed/generate_seed.py` |
| Generated seed (one atomic statement) | `supabase/seed.sql` |
| Anonymizer (one atomic statement) | `supabase/tools/anonymize.sql` |
| Seed checks S01–S32 | `supabase/tests/w6/seed_checks.sql` |
| Seed guard / atomicity / duplicate tests G00–G15 | `supabase/tests/w6/seed_guard_checks.sql` |
| Anonymizer tests A01–A29 | `supabase/tests/w6/anonymizer_checks.sql` |
| Run everything in one rolled-back block | `supabase/tests/w6/run_all_in_rollback.sql` |
| Before/after snapshot (read-only) | `supabase/tests/w6/staging_fingerprint.sql` |
| Verified staging backup | `supabase/tools/seed/backup_staging_data.sql` |
| Scoped seed replacement (staging) | `supabase/tools/seed/replace_staging_seed.sql` |

## 1. The seed

### 1.1 Safety rules
- **Invented data only.**
  - Names carry "(seed)".
  - Emails use the reserved `.test` domain (`seed.purple.test`), which can never receive mail.
  - Phone numbers are `+2340000000NNN`, references `SEED-…`, and the bank is "Seed Test Bank", code `000`.
- **One statement, atomic everywhere.** `seed.sql` is a single `DO` block, so in psql autocommit, the Supabase CLI and the SQL editor it either completes or changes nothing. `generate_seed.py --check` and test G00 enforce this structure, and G10 proves it: a failure forced in the messages section left 0 rows behind.
- **The guard is an allowlist and fails closed.** All of these must hold, or nothing happens:
  1. `purple.seed_target` is set, to `local` or an approved staging ref (today only `fwyviexwregngnqtwcra`).
  2. The target is not the production ref.
  3. Vault `project_url` exists, is readable and is not empty. A missing record (G06) and an unreadable one (G07) are both refusals.
  4. `project_url` is not the production URL (G08).
  5. `project_url` matches the target **exactly**: `https://<ref>.supabase.co` for staging, or a local address (`127.0.0.1`, `localhost`, `kong`, `host.docker.internal`) for `local`. Partial refs and mismatches are refused (G03–G05).
  6. There are no real accounts, meaning any email outside `@seed.purple.test` (G09).
  7. There is no completion marker. Otherwise the error is "already seeded" (G14).
  8. There is no seed data at all: no seed-domain account and none of the 219 seed IDs in 18 tables. Otherwise the error is "partial or older run, reset first" (G15, G15b).
- **Completion marker.** The last step writes the Vault secret `purple_seed_marker` with status, generator version, body digest, account count, target and time. Because the seed is atomic, the marker exists only if everything succeeded. Seed data without a marker means a partial or legacy run.
- **Passwords:**
  - None are stored in the repo.
  - The 31 test accounts use `purple.seed_password` if it is set, otherwise a random, unknown password.
  - **The admin always gets a random, unknown password and never the shared one** (G12).
  - Hashes are bcrypt **cost 10**, all distinct (G13).
  - The test password is not stored anywhere (G13b).
- **Deterministic.** IDs are fixed (md5 of a key), random choices use a fixed seed, and timestamps are relative to the run time.

### 1.2 What it contains
Unchanged from w6-1 (see S01–S30):
- 32 accounts: 1 admin, 12 buyers, 19 sellers covering product, freelance, home-service and creative personas, plus test-case accounts.
- 36 listings covering every type, status, category and delivery mode.
- 10 stories, 8 requests with 10 offers, 8 conversations with 21 messages.
- 4 orders, 3 bookings, 3 reviews, plus saves, follows, carts, reports and notifications.
- No promotions, campaigns or featured purchases (Phase 3).

### 1.3 Known limits
- Media files are placeholders (W7 for images, W10 for videos).
- No 2FA factors are seeded (W7).
- The admin cannot sign in by design. If W7 needs an admin session, that needs its own approved secret and setup.

## 2. Running it

**Staging:**
```sql
set purple.seed_target = 'fwyviexwregngnqtwcra';
-- optional, for the 31 test accounts only: set purple.seed_password = '<from a secret store>';
\i supabase/seed.sql
```
How it was loaded on 16/19 Nov: the workspace can't connect to the database directly, so staging fetched the committed file itself with `pg_net`, checked its SHA-256 and ran it. That method is described in §4.

**Local:**
1. Create the Vault record once: `select vault.create_secret('http://127.0.0.1:54321', 'project_url');`
2. Allow seeding once: `alter database postgres set purple.seed_target = 'local';`
3. Run `supabase db reset`; the seed then loads automatically.

**Recovery from a partial or legacy seed:** seeded accounts can't simply be deleted, because orders, verifications and other records block it and the seller register is append-only. Rebuild the database from the repo instead: migrations, then seed. See `docs/schema/STAGING-REBUILD-2026-11-19.md`.

**Regenerate after editing the generator:** `python3 supabase/tools/seed/generate_seed.py`, then commit both files.

## 3. The anonymizer

**Purpose:** if a copy of real data is ever needed for testing, it must be anonymized first. It is never run on production. Phase 1b staging uses synthetic data only.

**Guard:** the same allowlist as the seed, using `purple.anonymize_target`. Since remediation it requires an **exact** ref match. Before, a fragment of the URL such as `supabase` was accepted (N1, fixed; tests A20 and A20b). It also refuses an unreadable or missing Vault record (A21, A22) and `local` on a hosted project (A23). Production is refused by its ref (A02) and because production has no `project_url`.

**Atomicity:** it is one `DO` block. It pauses three guards (`reviews_protect`, `security_events_append_only`, `seller_status_history_append_only`) only inside its own transaction. If anything fails, PostgreSQL undoes the pause along with every change (review check I4). The header warns never to run its statements one by one.

| Replaced (deterministic pseudonyms from md5 of the row id) | Kept on purpose |
|---|---|
| Emails, phone, sign-in metadata, passwords (random, bcrypt 10), identity data | Account ids, roles, account status, dates |
| Display names, usernames, shop names, headlines, bios, avatars, covers, status reasons, **referral codes (F1)** | State and city (coarse; needed for search tests); skills and languages (professional tags) |
| Seller register snapshot, status-history reasons | Seller numbers, milestones, statuses |
| **Professional-page entry titles → "Experience entry" etc. (F2)**, organisations, locations, descriptions | Entry kind, years, order |
| ID document paths, bank account name/last 4/codes, **verification rejection notes (F4)** | Verification status and dates; bank name |
| Delivery names/phones/addresses, payment and payout references | Amounts, order and booking statuses |
| Messages, story comments, review text and replies, offer messages, request descriptions, report and dispute notes, notification text, booking details, **listing rejection reasons and story moderation notes (F4)** | Ratings; listing, story and request titles and descriptions (public marketplace content); search queries (anonymous) |
| Security-event and risk-flag details | Event and flag types |
| **Storage: ID-document rows removed; uploader metadata cleared on all rows (F3)** | Other storage rows: random names under the user's id folder (see `src/lib/upload.ts`) |
| Removed: sessions, refresh tokens, 2FA factors, one-time tokens, auth audit log, non-email identities | |

Files in Storage are never part of a database copy and must never be copied into a test project.

## 4. Test method and evidence (19 Nov 2026, staging `fwyviexwregngnqtwcra`)

**Method** (no lasting change to staging):
1. Fingerprint staging, read-only (`staging_fingerprint.sql`): a row count and checksum for every table in `public`, `private`, `auth` and `storage`, plus `vault.secrets` (encrypted values, never decrypted), `cron.job`, and a catalog checksum covering functions, triggers and their enabled state, policies and constraints. That is 87 objects.
2. `run_all_in_rollback.sql` runs, inside one block that always ends in a forced rollback:
   - the guard suite
   - removing the existing seed and loading the **current** seed fresh
   - the seed checks
   - the anonymizer suite

   Only the results are copied out before the rollback.
3. Fingerprint again, in the same session and in a fresh session. It must be identical.
4. Fallback if ever needed: rebuild staging from the repo.

Every script was fetched by staging from its commit and SHA-256 checked before running.

| Run | Commit | Result |
|---|---|---|
| First full run | `f558ab6` | anonymizer 31/31, seed 32/32, guard 18/19. The G00 failure was a **test bug**: `btrim()` doesn't remove newlines. The read-only re-check confirmed the seed file is one block |
| **Final full run** | **`959ec52`** | **83/83 pass**: guard 19/19 (G00–G15, incl. G00b, G13b, G15b), fresh load 1/1, seed 32/32, anonymizer 31/31 (A01–A29, incl. A20b, A24b) |
| Fingerprint | before / after / fresh session | **`a4390035f4c6be1d97a6e4e17b663df7`** all three times, 87 objects, **0 differences** |

SHA-256 of the tested files (`959ec52`):

| File | SHA-256 |
|---|---|
| `seed.sql` | `debbb321…f6e1d` |
| `anonymize.sql` | `bfb14792…529c3` |
| `seed_checks.sql` | `f4a4a0fb…8e22a` |
| `anonymizer_checks.sql` | `d5ea3453…6238d` |
| `seed_guard_checks.sql` | `856a72ee…a9877` |
| `run_all_in_rollback.sql` | `c86b15c1…ff5` |
| `staging_fingerprint.sql` | `38ce7f9f…78e40` |

**Notable results:**
- **Admin and passwords:** the admin hash does not match the shared test password, while the 31 test accounts do (G12). All 32 hashes are `$2a$10$` and distinct (G13).
- **Guard refusals:** missing Vault (G06), unreadable Vault (G07), production URL (G08), real account (G09), second run (G14), unmarked seed data (G15) and a single leftover seed ID (G15b) were all refused with their specific messages.
- **Atomicity:** a forced mid-seed failure left 0 rows (G10). A clean retry afterwards succeeded (G11).
- **Anonymizer:** the full sweep of every column in `public`, `private`, `auth` and `storage` found **no surviving original value** (A28). 128 foreign keys were checked with 0 broken (A29). F1–F4 each have their own test (A24–A27).

**Production** (read-only, after the runs): 7 users, 0 seed or anonymized accounts, 15 history rows, no `project_url` and no marker, all triggers enabled.

**Staging's stored seed** was replaced with w6-2 on 19 Nov (owner-approved); see §5.

### Earlier evidence (w6-1, 16–19 Nov)
Seed checks 30/30 and anonymizer A01–A19 at `113a950`, plus the W6 review report: superseded by the run above.

## 5. Staging seed replacement, w6-1 → w6-2 (19 Nov 2026, owner-approved)

| Step | What | Result |
|---|---|---|
| 1 | Fresh fingerprint, immediately before | `a4390035f4c6be1d97a6e4e17b663df7` (87 objects). Saved as `w6_backup_20261119.fingerprint_before` |
| 2 | Verified backup (`backup_staging_data.sql` @ `1d8e522`) | Schema **`w6_backup_20261119`**: copies of all **46** non-empty tables, **1,838** rows; each copy's md5 equals its source (**0 mismatches**); no access for `anon`/`authenticated` |
| 3 | Dry run of the deletion, rolled back | Deletes **only** old-seed rows: 34 seed tables to 0 (32 accounts, 36 listings, 21 messages …, 10 seed search rows). **Unchanged:** reference data (categories, sections, synonyms), platform tables, Vault, cron, storage buckets, append-only history. Status history +20 (its own "deleted" entries) |
| 4 | Replacement (`replace_staging_seed.sql` @ `1d8e522`), one transaction | Guarded: approved staging ref, verified backup, only seed accounts, no marker. Scoped delete, then load seed w6-2, then **S01–S32 inside the same transaction (32/32)**; any failure would have rolled everything back |
| 5 | Fingerprint after | `9d41b4197eb837644a52bb5a7569a901`. Catalog (functions, triggers + enabled, policies, constraints) **unchanged** |
| 6 | Full suites on the live w6-2 seed | seed 32/32, guard 19/19, anonymizer 31/31, live re-run refused 1/1. Fingerprint identical before and after the suites |

**What changed (rows before → after):**
- The 34 seed tables keep the same counts with new content (fresh timestamps, new salted cost-10 hashes, same 32 seed IDs). Two are byte-identical: `story_video_products` and `working_hours`.
- `vault.secrets` 1 → 2 (completion marker: digest `b10f52cb…`, generator w6-2, 32 accounts).
- Append-only history kept, not deleted: `security_events` 59 → 118, `seller_milestones` 116 → 232, `seller_register` 20 → 40 (the 20 old rows have `seller_id` null), `seller_status_history` 21 → 62.

**After the replacement:**
- 32 accounts: 1 admin, 12 buyers, 19 sellers.
- All hashes are bcrypt 10 and distinct, with 0 reused from the old seed.
- The admin has never signed in; there are no 2FA factors and no sessions.
- The storage cleanup queue is empty.

**Production** (read-only, afterwards): 7 users, 0 seed accounts, 15 history rows, no `project_url` or marker, no `w6_` schema, all triggers enabled.

**Recovery options:**
- **(a) Rebuild:** run migrations, then `seed.sql` (verified in the rollback runs: wipe, load, all checks pass).
- **(b) Backup:** `w6_backup_20261119` holds an exact copy of the old state. Restoring from it means removing the current seed rows (`replace_staging_seed.sql` deletion part) and inserting the backup tables back in foreign-key order, with the sign-up trigger in mind (profiles already exist after auth inserts).

**Keep or drop the backup schema:** owner decision. The suggestion is to keep it until W8 and then drop it with approval.
