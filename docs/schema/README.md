# Schema captures

| File | What | Captured | Integrity |
|---|---|---|---|
| `production-manifest-2026-11-16.tsv` | 470 objects from production (`nozxxxldfthbwhjwbsmy`): 125 functions (definition + grants), 47 tables (columns / constraints / indexes / triggers / RLS / grants), 235 policies, 29 types, 10 sequences, 3 buckets, 4 cron jobs, 1 trigger on `auth.users`, 8 extensions (+ versions) | 2026-11-16 23:32 UTC, PostgreSQL 17.11 | md5 of the manifest body = `c94e2bb776452aa3c2a9a0d7395fc047`, computed **in production** and matched against this file |

**How it was captured:** `supabase/tools/schema-manifest.sql`, run read-only through the Supabase connector. The query reads only system catalogs (definitions, policies, grants, bucket settings, cron job definitions). **No table rows, files, users, messages or personal data were read.** (ADR-001 / ADR-002 O2a)

**How to compare:** run the same query on another database and compare line by line:
`python3 supabase/tools/compare-manifests.py docs/schema/production-manifest-2026-11-16.tsv <other>.tsv`

**Fingerprint format**
- function: `md5(pg_get_functiondef)[:12] / md5(sorted grants)[:6]`
- table: `columns . constraints . indexes . triggers . rls . grants` (each a short md5), so a mismatch shows which part differs
- policy: md5 of command, permissive, sorted roles, USING and WITH CHECK
- cron: md5 of schedule + command, with the project ref replaced by `<ref>`
- extension_version: allowed to differ between environments (documented)
