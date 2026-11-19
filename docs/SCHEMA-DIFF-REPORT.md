# Schema comparison: clean staging rebuild vs production (checkpoint C1 evidence)

**Date:** 2026-11-16 · **Status:** for owner review at C1. No production changes were made.

## 1. What was compared

| | Production | Staging |
|---|---|---|
| Project | `nozxxxldfthbwhjwbsmy` (PURPLE VENDRA) | `fwyviexwregngnqtwcra` (purple-shop-staging, eu-west-2, free plan, created 2026-11-16) |
| PostgreSQL | 17.11 | 17.12 |
| How built | Hand-applied 001–011 + 15 recorded migrations | **Empty project → repo migrations 001–022 only** (including reconstructed 011), from commit `d4f1560` |
| Manifest | `docs/schema/production-manifest-2026-11-16.tsv` (470 rows, md5 `c94e2bb7…` verified in production) | Same query (`supabase/tools/schema-manifest.sql`), compared row by row in staging against production's 470 row fingerprints |

How staging was built: see `docs/schema/STAGING-REBUILD-2026-11-16.md`. All 22 files applied without error; each file's SHA-256 was checked against the commit before running.

## 2. Result

| Count | Meaning |
|---|---|
| **470 / 470** | Objects in each database: same set of names, nothing missing on either side |
| **446** | Identical fingerprints |
| **24** | Differ. Classified below: **23 explained and allowed, 1 real gap** |

**Identical in every case:** all 47 tables (columns, constraints, indexes, triggers, RLS, grants), all 235 RLS and storage policies, all 29 types, all 10 sequences, all 3 storage buckets, all 4 cron jobs (storage-cleanup with the project ref normalized), the `auth.users` trigger, the extension list, and the grants on all 125 functions.

## 3. The 24 differences

| # | Object(s) | Kind of difference | Evidence | Behaviour | Classification |
|---|---|---|---|---|---|
| 1 | `supabase_vault` extension version | 0.3.1 (prod) vs 0.3.2 (staging) | manifest | Platform-managed | **Allowed:** environment |
| 2–6 | `enforce_home_service_verification`, `protect_review`, `refresh_seller_rating`, `set_updated_at`, `validate_review` | **Line endings only.** Production bodies contain Windows `\r\n` (pasted from Windows into the SQL editor); the repo has `\n` | md5 of definition after `\r\n → \n` is **identical** in both databases; production has exactly 5 functions containing `\r`, and these are them | Identical | **Allowed:** cosmetic |
| 7–23 | `track_seller_profile`, `accept_offer`, `block_contact_details`, `check_listing_risk`, `check_message_risk`, `close_request`, `contact_problem`, `guard_pro_fields`, `log_search`, `protect_listing_fields`, `protect_profile_fields`, `protect_report`, `protect_seller_verification`, `protect_story_video`, `record_story_event`, `search_suggest`, `send_offer` | **Comments/whitespace only.** Production's copies have `--` comments removed (consistent with those migrations being applied through the migration tool, which recorded comment-free SQL) | md5 after removing `--…` comments and all whitespace is **identical** in both databases for all 17 | Identical | **Allowed:** cosmetic. *Limitation:* this normalization would also hide a difference inside a `--…` sequence in a string literal. Full texts can be spot-checked on request, and pgTAP behaviour tests (W7) give independent cover |
| **24** | **`public.escalate_report()`** | **Real difference.** Production has the request-report branch; the repo version does not | Normalized md5 still differs. Full text compared (§4) | **Different** | **Gap in the repo:** fixed by the C1 layout (§5) |

The allowed list is in `docs/schema/allowed-differences.tsv`; `compare-manifests.py --allow` uses it.

## 4. `escalate_report()`: what the repo is missing

Repo file 020 says the final function was "applied live; see `pg_get_functiondef(...)`", but it doesn't contain the code. Production's history row `20261112181916 request_reports_escalation` contains it. Compared with the version a repo-only rebuild produces, production's version:

1. Adds `request_id` to the `report_filed` audit details.
2. **Adds a request branch:** when 3 or more accounts older than 3 days report the same buyer request, it closes the request, declines its waiting offers, logs `request_auto_closed` and raises a `request_reported` (high) flag on the buyer.
3. Wraps the "reported user, 30 days" check in `if new.reported_user_id is not null` (needed because request reports deliberately store no user).

**Impact if not fixed:** a database rebuilt from today's repo would never auto-close heavily reported buyer requests. Production behaviour is correct. **No production change is needed**; only the repo is behind.

## 5. Content-level check of each production history row

Normalized md5 (CRLF→LF, `--` comments removed, whitespace removed) of production's recorded SQL vs the repo file:

| Production version | Name | Repo file | Match |
|---|---|---|---|
| 20261111114059 | vendra_stories | 012 | ✅ identical |
| 20261111131447 | orders_read_access | 013 | ✅ identical |
| 20261111141906 | search_profiles | 014 (merged) | ⚠️ merged; end state identical |
| 20261111141945 | search_word_similarity | 014 (merged) | ⚠️ merged; end state identical |
| 20261112153210 | rename_purple_shop | 015 | ✅ identical |
| 20261112154821 | messaging_no_contact | 016 (merged) | ⚠️ merged; end state identical |
| 20261112154910 | messaging_lock_block_helper | 016 (merged) | ⚠️ merged; end state identical |
| 20261112161210 | faster_blocked_account_rules | 017 | ✅ identical |
| 20261112161822 | search_everything | 018 | ✅ identical |
| 20261112162702 | saved_items | 019 | ✅ identical |
| 20261112181843 | purple_requests | 020 (merged) | ⚠️ merged |
| 20261112181859 | request_reports_keep_buyer_hidden | 020 (merged) | ⚠️ merged; end state identical |
| 20261112181916 | request_reports_escalation | 020 (merged) | ❌ **code missing from repo** (§4) |
| 20261112230307 | seller_records | 021 | ✅ identical |
| 20261114125544 | pro_profiles | 022 | ✅ identical |

"Merged" means the repo file was edited in place, so it isn't the production rows joined together (checked: normalized md5 of the concatenation differs). That's why Option A uses production's recorded SQL for the split files: it's exactly what ran.

## 6. Allowed environment-specific differences (not schema)

| Item | Production | Staging | Why allowed |
|---|---|---|---|
| PostgreSQL minor | 17.11 | 17.12 | New projects get the current minor version |
| Vault secrets | `project_url` not present (storage-cleanup URL was typed in by hand) | `project_url`, plus a temporary runner token (removal pending, see §8) | Per environment; values never copied |
| storage-cleanup cron URL | `…nozxxxldfthbwhjwbsmy…` | `…fwyviexwregngnqtwcra…` | Normalized in the manifest; fingerprints match |
| Migration history | 15 rows | none (built by the runner) | Excluded; reconciled separately (P1, not approved) |
| Edge Functions | `storage-cleanup` v1 | `staging-migration-runner` (temporary) | Staging tool only; storage-cleanup gets deployed to staging in W10 |
| `pg_net` | created by hand | created just before the rebuild so the runner could be invoked; 011's `create extension if not exists` then no-ops | Same final state (extension list identical) |
| Data | real users | none (no seed yet) | Synthetic seed is W6, after C1 |

## 7. Conclusion

A database built only from the repo plus the reconstructed 011 reproduces production **exactly**, apart from 22 cosmetic function-text differences, 1 platform version difference, and **one real code gap (`escalate_report`)**. The gap closes when the repo layout mirrors production history (Option A), because production's recorded SQL for `request_reports_escalation` becomes a repo file.

## 8. Open housekeeping item

The one-time runner token is still in staging's Vault. My delete query needed your confirmation in the Supabase connector and timed out waiting. Risk is low: the runner only works on staging, only runs migration files from a pinned commit, and every call would fail on objects that already exist. I'll delete it on your go-ahead (or you can: Staging → Vault → delete `migration_runner_token`).

## 9. After C1 (2026-11-19)

C1 was approved and Option A applied. Staging was reset and rebuilt from the new 26-file layout (commit `002311a`):
- **470/470** objects present on both sides
- **453** identical (was 446)
- **17** allowed: `supabase_vault` version, plus 16 functions with CRLF or comment-only differences
- **0 unexplained.** `escalate_report()` is now identical to production.

Details: `docs/schema/STAGING-REBUILD-2026-11-19.md`. The allowed list was reduced to 17 rows. The one-time runner token (§8) is still pending deletion.
