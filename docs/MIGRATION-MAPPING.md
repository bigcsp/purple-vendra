# Repository ↔ production migration mapping (preliminary, v1.2)

**Status:** preliminary. It's based on file names, sizes and keyword checks in the repo, plus production's `supabase_migrations.schema_migrations` (read-only query, 16 Nov 2026).
Phase 1b workstream W3 turns this into a **content-level** mapping: each repo file is compared statement by statement with production's recorded SQL and live object definitions. **Repo files won't be renamed or split until you've reviewed the final mapping, and production history won't be touched without your separate approval (P1).**

## Facts

- Production history has **15 rows**. The first is `20261111114059 vendra_stories`. Repo files 001–011 were run by hand in the SQL editor, so they have **no history rows**.
- The repo has **21 migration files** (001–010, 012–022). **011 is missing.**
- None of production's version numbers match a repo file name. Repo files use `2026MMDD0000NN`; production uses the time each migration was applied.
- The four production rows without a file of their own **are not missing SQL**. Their content was folded into repo files 014, 016 and 020 (keyword check below).

## Mapping

| Repo file | Production history row(s) | Relationship | Evidence | Action in W3 |
|---|---|---|---|---|
| 001 initial_schema … 010 fraud_signals (10 files) | none | Run by hand | No history rows; objects exist (to be confirmed by W5 diff) | Keep the files. Mark them applied in production only through **P1** |
| **011 (privacy & data rights)** | none | **File missing** | Production has `storage_deletion_queue`, `queue_file_deletion()`, `run_privacy_retention()`, `request_account_deletion()`, `cancel_account_deletion()`, `profiles.deletion_requested_at`, cron `privacy-retention` + `storage-cleanup`, Edge Function `storage-cleanup` v1. Repo 012 already calls `queue_file_deletion`, so a clean rebuild **fails at 012** today. | Reconstruct from the captured production definitions. Add the Edge Function code to `supabase/functions/storage-cleanup/` |
| 012 vendra_stories | 20261111114059 vendra_stories | 1 : 1 | Same name. Production 46,019 chars vs repo 50,420 bytes; most likely comments stripped | Content diff |
| 013 orders_read_access | 20261111131447 orders_read_access | 1 : 1 | Same name | Content diff |
| 014 search_profiles | 20261111141906 search_profiles **+** 20261111141945 search_word_similarity | **1 : 2** | `word_similarity(...)` is already in repo 014 | Split into 2 files matching production (Option A) |
| 015 rename_purple_shop | 20261112153210 rename_purple_shop | 1 : 1 | Same name | Content diff |
| 016 messaging_no_contact | 20261112154821 messaging_no_contact **+** 20261112154910 messaging_lock_block_helper | **1 : 2** | Repo 016 line 230 already revokes `is_blocked_between` from `public, anon, authenticated` (production follow-up revoked it from `authenticated`) | Split (Option A) |
| 017 faster_blocked_account_rules | 20261112161210 | 1 : 1 | Same name | Content diff |
| 018 search_everything | 20261112161822 | 1 : 1 | Same name | Content diff |
| 019 saved_items | 20261112162702 | 1 : 1 | Same name | Content diff |
| 020 purple_requests | 20261112181843 purple_requests **+** 20261112181859 request_reports_keep_buyer_hidden **+** 20261112181916 request_reports_escalation | **1 : 3** | Repo 020 line 534 says these were "applied as follow-up migrations"; `reports_check`, `escalate_report()` are present | Split (Option A) |
| 021 seller_records | 20261112230307 | 1 : 1 | Same name | Content diff |
| 022 pro_profiles | 20261114125544 | 1 : 1 | Same name; production SQL references the repo file | Content diff |
| `run-in-sql-editor/004_005_006_combined.sql` | n/a | Convenience bundle, not a migration | n/a | Move to `docs/legacy/` (repo only) |

## Alignment options (decided after the content diff; your choice at checkpoint C1)

- **Option A (recommended): mirror production history one-to-one.**
  - Files 001–011 keep their early timestamps. They sort before `20261111114059`, which is correct.
  - Files 012–022 are renamed, or split where needed, to production's exact versions. The result is **26 files**: 11 hand-applied + 15 recorded.
  - Production history then needs **11 new rows only** (001–011), via `supabase migration repair --status applied`. That's **P1**, a separate approval. Existing rows are never changed.
- **Option B: squash a baseline.** One baseline file replaces 001–022, and production history is rewritten to match it. This **deletes history**, so it's not recommended.

## Expected environment-specific differences (allowed in the schema diff, each one documented)

| Area | Why it differs | How the diff handles it |
|---|---|---|
| `cron.job` command for `storage-cleanup` | Contains the project URL (`https://<ref>.supabase.co/functions/v1/...`) | Normalize `<ref>` before comparing |
| `cron.job` ids / `jobid` | Assigned on creation | Compare by `jobname` + schedule + normalized command |
| `supabase_migrations.schema_migrations` | Production has hand-applied history; staging is built cleanly | Excluded from the schema diff; reconciled separately (P1) |
| Supabase-managed schemas (`auth`, `storage` internals, `realtime`, `graphql`, `extensions`, `vault`, `net`, `cron` tables) | Owned and versioned by Supabase | Excluded, **except** our storage policies, bucket config, cron job definitions and the extension list |
| Postgres / extension minor versions | Production 17.11; a new project may get a newer minor version | Recorded; differences in functions installed by extensions are ignored |
| Default privileges / owners for `supabase_admin` roles | Platform-managed | Excluded unless they affect our objects' grants |
| Auth settings (site URL, redirect URLs, SMTP, MFA, password policy) | Configuration, not schema; leaked-password protection is Pro-only | Documented in the environment matrix, not the schema diff |
| Edge Function secrets, Vault secrets | Per environment | Names listed; values never copied |
| Data rows (users, listings, storage objects, sequence values) | Synthetic on staging | Excluded (data, not schema) |
| Rows seeded by migrations (categories, sections, synonyms) | Should be identical | **Compared**; any difference is a real drift |
| Edge Function `verify_jwt` and code | Should be identical | **Compared** by code hash |

## Finding recorded while mapping

`storage-cleanup` is deployed with `verify_jwt: false`, and the nightly cron calls it with no auth header [Fact], so anyone with the URL can trigger it. Its code only deletes files already queued by the database and is safe to repeat, so the risk is **low** (mostly wasted function calls). Proposed fix: a shared-secret header. That's a production change, so it isn't part of Phase 1b (see P4).
