# ADR-001: Production change freeze and change-control rules

- **Status:** approved
- **Date:** 2026-11-16
- **Approved by:** owner, 16 Nov 2026 (Phase 1b approval, condition 1: "Do not modify production application code, database schema, migration history, storage policies or production settings during Phase 1b.")
- **Phase:** 1b

## Context
The Phase 1 audit found that production has database objects that are not in the repository. Migration 011 was never committed, and migrations 001–011 were run by hand in the SQL editor. The repository therefore can't rebuild production. Any further hand-made change would widen that gap.

## Decision
1. **Freeze.** From 16 Nov 2026, no DDL, policy, storage, cron, Edge Function, Auth setting or migration-history change is made to the production project (`nozxxxldfthbwhjwbsmy`) by hand or by Claude.
2. **During Phase 1b, Claude may only read production catalog metadata** (approval O2a): schema definitions, policies, grants, cron job definitions, bucket configuration and Edge Function code. **No table rows, messages, files or personal data are read or copied.**
3. **Production changes after the freeze** happen only:
   - as a migration file in the repository,
   - tested on staging first,
   - run through the gated `deploy-production-db` workflow,
   - after the owner's explicit approval for that specific change (P1, P2, P3, …),
   - and recorded in `docs/DB-CHANGELOG.md`.
4. **Emergency exception.** If the owner must make an urgent hand change (for example, a security incident), they record it in `docs/DB-CHANGELOG.md` the same day, and it is back-filled as a migration before any other work continues.

## Consequences
- Production behaviour stays exactly as it is today throughout Phase 1b.
- Bugs found in production during Phase 1b are recorded as known issues; they are not hot-fixed.
- The end-of-phase re-capture of the production schema must match the W2 capture (acceptance criterion 3).
