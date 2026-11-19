# Database change log

Every change to a Purple Shop database (staging or production) gets an entry here. Production entries need an owner approval reference.

| Date | Environment | Change | Migration / command | Why | Risk | Rollback | Staging result | Approval |
|---|---|---|---|---|---|---|---|---|
| 2026-11-06 → 2026-11-14 | production | Migrations 001–011 applied by hand in the SQL editor; 012–022 via migration tool (15 history rows) | see `docs/MIGRATION-MAPPING.md` | Pre-freeze history, recorded for completeness | n/a | n/a | n/a | pre-freeze |
| 2026-11-16 | production | **Change freeze starts** (ADR-001). Read-only catalog capture only. | — | Phase 1b | none | n/a | n/a | ADR-002 |
| 2026-11-16 | **staging** | Project `purple-shop-staging` (`fwyviexwregngnqtwcra`) created, eu-west-2, free plan | Supabase create_project | O1 | none | delete project | n/a | ADR-002 O1 |
| 2026-11-16 | **staging** | pg_net extension, Vault secrets `project_url` + one-time `migration_runner_token`; Edge Function `staging-migration-runner` (temporary) | SQL + deploy | Needed to build staging from repo bytes | low (staging only) | delete function / secrets | n/a | ADR-002 O1 |
| 2026-11-16 | **staging** | Clean build: repo migrations 001–022 incl. reconstructed 011, commit `d4f1560` | runner (SHA-256 checked) | W5 rebuild | none | reset staging | ✅ all 22 applied; 446/470 identical, 23 cosmetic/platform, 1 real gap (escalate_report) | ADR-002 |
| 2026-11-16 | production | **No change.** Read-only catalog queries only (manifest, function definitions, history statements, edge function source) | — | W2/W3 | none | n/a | n/a | O2a |
| 2026-11-19 | production | **No change.** Read-only: aggregate user count; recorded migration SQL for 7 history rows (md5 checks); function definitions for the post-C1 comparison | — | C1 Option A, owner question | none | n/a | n/a | O2a |
| 2026-11-19 | **staging** | Reset: cron jobs, auth trigger, storage policies/buckets, `private` schema, all `public` objects, `pg_trgm`, `pg_cron` dropped (default privileges, `pg_net`, Vault kept) | guarded SQL, one transaction | A9 clean rebuild | none (staging, no data) | rebuild from repo | ✅ empty | C1 (owner, 2026-11-19) |
| 2026-11-19 | **staging** | Clean build from the C1 layout: 26 files, commit `002311a` | runner (SHA-256 checked) | A9 | none | reset staging | ✅ all 26 applied; 470/470, 453 identical, 17 allowed, 0 unexplained | C1 (owner, 2026-11-19) |