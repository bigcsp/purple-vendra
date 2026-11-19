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
| 2026-11-19 | **staging** | Vault secret `migration_runner_token` deleted (runner now inert) | SQL delete | Owner request after C1 | none | n/a (runner retired) | ✅ | Owner, 2026-11-19 |
| 2026-11-19 | **staging** | Synthetic seed loaded: 32 accounts and app data (no schema change) | `supabase/seed.sql` @ `f44835f`, fetched by pg_net, SHA-256 checked, one transaction | W6 | none (synthetic, staging) | rebuild staging from repo | ✅ seed checks 30/30 | Phase 1b W6 (ADR-002) |
| 2026-11-19 | **staging** | Anonymizer tests: ran and rolled back (no lasting change) | `anonymize.sql` + `anonymizer_checks.sql` @ `9085ced` | W6 | none | automatic rollback | ✅ 19/19; data unchanged afterwards | Phase 1b W6 |
| 2026-11-19 | production | **No change.** Read-only check: 7 users, 0 seed accounts, 15 history rows | — | W6 evidence | none | n/a | n/a | O2a |
| 2026-11-19 | **staging** | W6 remediation test runs (2): guard, atomicity, fresh seed load, seed and anonymizer suites, all inside one rolled-back block. **No lasting change** | `run_all_in_rollback.sql` @ `f558ab6`, then `959ec52` | W6 remediation evidence | none (rolled back) | automatic rollback; rebuild from repo as fallback | ✅ 83/83 final; fingerprint `a4390035…` identical before/after (87 objects) | Owner, 2026-11-19 |
| 2026-11-19 | production | **No change.** Read-only: 7 users, 0 seed accounts, 15 history rows, no project_url or marker, triggers enabled | — | W6 remediation evidence | none | n/a | n/a | O2a |