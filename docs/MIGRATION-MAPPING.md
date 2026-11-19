# Repository ↔ production migration mapping (FINAL for checkpoint C1)

**Status:** content-level, verified 2026-11-16. **C1 approved by the owner on 2026-11-19 (Option A). Applied in the repo (commit `002311a`) and verified on staging; see §5.** Production history is untouched (P1 not approved).
Evidence: `docs/SCHEMA-DIFF-REPORT.md`, `docs/schema/production-manifest-2026-11-16.tsv`, `docs/schema/STAGING-REBUILD-2026-11-16.md`.

## 1. Current mapping (verified)

| Repo file (today) | Production history row(s) | Content check (normalized md5) | End-state check (staging rebuild vs production) |
|---|---|---|---|
| 001 initial_schema … 010 fraud_signals | none: applied by hand | n/a (no recorded SQL) | ✅ all objects identical, apart from cosmetic CRLF in 5 functions created here |
| **011 privacy_data_rights** (reconstructed, new file) | none: applied by hand | n/a | ✅ table, columns, 6 functions, grants and 2 cron jobs identical |
| 012 vendra_stories | 20261111114059 vendra_stories | ✅ identical | ✅ |
| 013 orders_read_access | 20261111131447 orders_read_access | ✅ identical | ✅ |
| 014 search_profiles | 20261111141906 search_profiles + 20261111141945 search_word_similarity | ⚠️ merged in place | ✅ |
| 015 rename_purple_shop | 20261112153210 rename_purple_shop | ✅ identical | ✅ |
| 016 messaging_no_contact | 20261112154821 messaging_no_contact + 20261112154910 messaging_lock_block_helper | ⚠️ merged in place | ✅ |
| 017 faster_blocked_account_rules | 20261112161210 | ✅ identical | ✅ |
| 018 search_everything | 20261112161822 | ✅ identical | ✅ |
| 019 saved_items | 20261112162702 | ✅ identical | ✅ |
| 020 purple_requests | 20261112181843 purple_requests + 20261112181859 request_reports_keep_buyer_hidden + 20261112181916 request_reports_escalation | ⚠️ merged; **`escalate_report` code missing** | ❌ `escalate_report` differs (only real gap) |
| 021 seller_records | 20261112230307 | ✅ identical | ✅ |
| 022 pro_profiles | 20261114125544 | ✅ identical | ✅ |

Every production history row maps to a repo file, and every repo file maps to a history row or is "applied by hand".

## 2. Proposed layout: Option A (mirror production history one-to-one) → **your decision at C1**

| # | Action (repo only) | Content source | Why |
|---|---|---|---|
| A1 | Keep 001–010 as they are | repo | Already reproduce production |
| A2 | Keep **011** (reconstructed) | production catalog | Verified identical end state |
| A3 | Rename 012, 013, 015, 017, 018, 019, 021, 022 to production's exact version numbers (e.g. `20261110000012_vendra_stories.sql` → `20261111114059_vendra_stories.sql`) | **repo text, unchanged** (keeps comments) | Content already identical to production's record |
| A4 | Replace merged **014** with two files: `20261111141906_search_profiles.sql`, `20261111141945_search_word_similarity.sql` | **production's recorded SQL**, verbatim, with a provenance header comment | Exactly what ran in production; the merged repo text can't be split back reliably |
| A5 | Replace merged **016** with `20261112154821_messaging_no_contact.sql`, `20261112154910_messaging_lock_block_helper.sql` | production's recorded SQL | Same reason |
| A6 | Replace merged **020** with `20261112181843_purple_requests.sql`, `20261112181859_request_reports_keep_buyer_hidden.sql`, `20261112181916_request_reports_escalation.sql` | production's recorded SQL | Same reason, and **this restores the missing `escalate_report` code** |
| A7 | Keep the replaced merged files under `docs/legacy/migrations-pre-c1/` (not run) | — | Keeps their comments and history readable |
| A8 | Move `run-in-sql-editor/004_005_006_combined.sql` to `docs/legacy/` | — | Not a migration |
| A9 | **Verify:** reset staging, rebuild from the new layout, re-run the manifest comparison | — | Target: 470/470, **0 unexplained**, only the 23 allowed rows from `allowed-differences.tsv` |

**Result:** 26 files (11 hand-applied + 15 matching production history one-to-one). When **P1** is separately approved, production history needs **only 11 new rows** (001–011) and no existing row changes.

Trade-off of A4–A6: production's recorded SQL has no comments, so those 7 files lose the explanatory comments (kept in `docs/legacy/`). The alternative (re-splitting the commented repo text by hand) risks another silent mismatch like `escalate_report`.

### Option B: squash a baseline (not recommended)
One baseline file replaces 001–022, and production history is rewritten to match it. That loses history and needs a destructive production history change.

## 3. Allowed differences after Option A (expected)

From `docs/schema/allowed-differences.tsv`: `supabase_vault` version (platform), 5 functions with CRLF line endings, and 17 functions whose production copies have their comments stripped. All are behaviour-identical. Production keeps its current text; **no production change is proposed** for these.

## 4. Decisions requested at C1

1. **Approve Option A**, steps A1–A9 (repo and staging only).
2. **Accept the 23 allowed differences** as listed.
3. **Accept the reconstructed 011.**
4. Confirm that **P1** (adding the 11 history rows to production) stays a separate, later approval.

## 5. Applied (2026-11-19, after C1 approval)

Option A steps A1–A9 were carried out in the repo and on staging only.
- **A3:** 8 files renamed to production's versions; SHA-256 unchanged.
- **A4–A6:** 7 files created from production's recorded SQL, each md5-checked against `supabase_migrations.schema_migrations` (read-only). Two of them were rebuilt without retyping: `messaging_no_contact` (former 016 with comments removed and the `is_blocked_between` revoke as it was before 20261112154910) and `purple_requests` (former 020 up to the reports index, plus production's original `protect_report()`). The md5 check confirmed both.
- **A7/A8:** 3 merged files and the 004–006 SQL-editor bundle moved to `docs/legacy/`.
- **A9:** staging reset and rebuilt from the 26 files: **470/470 objects, 453 identical, 17 allowed, 0 unexplained**; `escalate_report()` now identical. Evidence: `docs/schema/STAGING-REBUILD-2026-11-19.md`.

Final layout (26 files): 001–011 (applied by hand in production; history rows are added only under **P1**) + 15 files whose versions equal production's 15 history rows one-to-one.
