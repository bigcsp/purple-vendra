# W6: Synthetic seed and anonymizer

**Status:** complete, awaiting owner review (W6 checkpoint). **Date:** 19 Nov 2026.
**Scope:** staging and local databases only. Production was not read for data and not changed.

| Deliverable | File |
|---|---|
| Seed generator (deterministic) | `supabase/tools/seed/generate_seed.py` |
| Generated seed | `supabase/seed.sql` (182 KB, 473 inserts) |
| Anonymizer | `supabase/tools/anonymize.sql` |
| Seed checks (30) | `supabase/tests/w6/seed_checks.sql` |
| Anonymizer tests (19) | `supabase/tests/w6/anonymizer_checks.sql` |

## 1. The seed

### 1.1 Safety rules built into the file
- **Invented data only.** Names carry "(seed)", e.g. "Adaeze (seed buyer)" and "Adire House (seed)". Emails use the reserved `.test` domain (`seed.purple.test`), which can never receive mail. Phone numbers are `+2340000000NNN`. References look like `SEED-CHECKOUT-0001`.
- **Never on production.** The seed refuses to run if the database has any account outside `@seed.purple.test`, or if the Vault `project_url` is the production project.
- **Never twice.** It refuses to run if the seed admin already exists.
- **No passwords in the repo.** Each account's password comes from the session setting `purple.seed_password` if one is set. Otherwise every account gets a random password that nobody knows, so nobody can sign in. W7 will set this from a GitHub secret.
- **Deterministic.** IDs are fixed (md5 of a key) and the random choices use a fixed seed, so the generator always writes the same file. `generate_seed.py --check` fails if `seed.sql` is out of date. Timestamps are relative to when the seed runs, such as "3 days ago", so the data always looks recent.

### 1.2 What it contains (counts on staging after loading)

| Area | Content |
|---|---|
| Accounts | 32: 1 admin, 12 buyers, 19 sellers |
| Seller personas | product sellers (6: fashion/adire, art and crafts), freelancers (5: tech, digital design), home-service pros (4), creatives and talent (4) |
| Test-case accounts | banned buyer, suspended buyer, suspended shop, buyer with deletion requested, seller with ID check pending (draft listings only), seller with ID check rejected, seller without a public pro page |
| Listings | 36: every type (product 15, service 15, talent 6), every status (draft, pending, approved, rejected with reason, removed), every category, all 5 delivery modes, quote-on-request; 51 image paths |
| Seller details | 18 ID checks (approved, pending, rejected), 8 service areas, 24 working-hour rows, 23 professional-page entries (6 public pages, both modes) |
| Purple Stories | 10 (8 published, 1 draft, 1 hidden), 8 tagged products, 25 likes, 16 comments, 868 anonymous events |
| Purple Requests | 8 (open, closed with an accepted offer, closed without, expired), 10 offers in all four statuses |
| Messaging | 8 conversations, 21 messages, read and unread, one from an accepted request offer |
| Orders and bookings | 4 checkouts and orders (completed, shipped, delivered), 5 items, 2 payouts, 3 bookings (completed, scheduled, requested), 3 reviews (one with a seller reply) |
| Other | 36 saves, 27 follows, 3 cart items, 1 block, 3 reports (listing, request, user), 5 notifications, 10 searches, 61 listing views, 1 referral, 1 share link |

The admin account also appears in the seller register (20 rows). This is existing app behaviour: the register tracks the `admin` role as well as `seller`.

### 1.3 Known limits (for later workstreams)
- **Media files are placeholders.** The listing-image and story paths follow the real folder rules, but the files don't exist yet, so pictures and videos show as missing on staging. Uploading sample media needs the staging service key in CI: **W7** for images, **W10** for videos.
- **No 2FA factors are seeded.** Seller-only pages need 2FA. W7 will enrol a TOTP factor for the test seller during the test run, with its secret held in GitHub secrets.
- Promotions, campaigns and featured purchases are **not seeded**, because Phase 3 work is out of scope.

## 2. Running it

**Staging** (how it was loaded on 19 Nov). The workspace can't connect to the staging database directly, so staging fetches the committed file itself with `pg_net`, checks its SHA-256 and runs it in one transaction:
```sql
select net.http_get('https://raw.githubusercontent.com/bigcsp/purple-vendra/<commit>/supabase/seed.sql');  -- returns an id
do $$ declare s text; begin
  select content into s from net._http_response where id = <id> and status_code = 200;
  if encode(extensions.digest(convert_to(s, 'UTF8'), 'sha256'), 'hex') <> '<sha256 of the file>' then raise exception 'sha mismatch'; end if;
  execute s;
end $$;
```
**Local:** `supabase db reset` loads `supabase/seed.sql` automatically. To be able to sign in, run `set purple.seed_password = '...'` first in the same session.

**Regenerate after editing the generator:** `python3 supabase/tools/seed/generate_seed.py`, then commit both files.

## 3. The anonymizer

**Purpose:** if a copy of real data is ever needed for testing, it must be anonymized first. It is never run on production. Phase 1b staging uses synthetic data only (B4.4), so the anonymizer has only ever run against the seed, inside a test that is rolled back.

**Guards:**
- You must set `purple.anonymize_target` to the project ref.
- The ref must match the database's Vault `project_url`.
- The production ref is always refused.

The script creates no database objects. It pauses three protective triggers (`reviews_protect`, `security_events_append_only`, `seller_status_history_append_only`) and turns them back on before it finishes, all within one transaction.

| Replaced (deterministic pseudonyms from md5 of the row id) | Kept |
|---|---|
| Emails, phone, sign-in metadata, passwords (random), identity data | Account ids, roles, account status, created dates |
| Display names, usernames, shop names, headlines, bios, avatars, covers, status reasons | State and city (coarse location, needed for search tests) |
| Seller register snapshot, status-history reasons | Seller numbers, milestones, statuses |
| ID document paths, bank account name/last 4/codes | Verification status and dates |
| Delivery names/phones/addresses, payment and payout references | Amounts, order and booking statuses |
| Messages, story comments, review text and replies, offer messages, request descriptions, report and dispute notes, notification text, booking details | Ratings, request titles, listing and story content (public marketplace content) |
| Security-event and risk-flag details | Event and flag types |
| Removed: sessions, refresh tokens, 2FA factors, one-time tokens, auth audit log, non-email identities | Search queries (anonymous already) |

## 4. Test evidence (staging, 19 Nov 2026)

All results come from staging (`fwyviexwregngnqtwcra`). Each script was fetched from its commit and its SHA-256 checked before running.

| Suite | Script commit | Result |
|---|---|---|
| Seed load | `supabase/seed.sql` @ `f44835f` (sha256 `6a58e5b2…7c0f`) | ✅ loaded in one transaction, no errors |
| Seed checks S01–S30 | `seed_checks.sql` @ `7195e33` (sha256 `7bd8645c…04e9`) | ✅ **30/30** (run before and after the anonymizer test) |
| Second-seed guard G01 | seed @ `f44835f` | ✅ refused: "this database is already seeded" |
| Anonymizer A01–A19 | `anonymize.sql` + `anonymizer_checks.sql` @ `9085ced` | ✅ **19/19** |

**Seed checks** cover:
- accounts and personas (S01–S05)
- listing coverage and rules (S06–S13)
- pro pages (S14)
- stories and counters (S15–S17)
- requests and offers (S18–S20)
- messaging (S21)
- reviews, ratings and payouts (S22–S24)
- **no seeded text trips the contact-details rule** (S25)
- test-case accounts (S26)
- public search and the request board behaving correctly on the seed (S27–S28)
- no real-looking emails or phone numbers (S29–S30)

**Anonymizer tests** cover:
- the three refusal guards (A01–A03)
- row counts unchanged in 19 tables (A04)
- every personal field replaced (A05–A10, A12–A14, A17)
- ratings and links kept (A11)
- protective triggers back on (A15)
- public search unchanged, 28 listings (A16)
- a second run gives an identical result (A18)
- the database is unchanged after the test rolls back (A19)

The first anonymizer run stopped on the `seller_status_history` append-only guard. The run rolled back and nothing changed. The anonymizer now pauses that guard inside its own transaction, as it already did for the review and audit-log guards (fix in `9085ced`).

**Production:** read-only check after W6: 7 users, 0 seed accounts, 15 migration-history rows (unchanged).
