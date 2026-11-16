# ADR-002: Phase 1b approvals and conditions

- **Status:** approved
- **Date:** 2026-11-16
- **Approved by:** owner, 16 Nov 2026
- **Phase:** 1b

## Approved decisions
| # | Decision |
|---|---|
| O1 | Create a second **free** Supabase project for staging, region **eu-west-2** |
| O2a | Read-only access to production **catalog** information for schema capture; **no production data copied** |
| O3 | Paystack + Supabase Edge Functions is the planned payment architecture. **No payment implementation in Phase 1b.** |
| O14 | Design a separate break-glass administrator account with strict access controls and audit logging (design only in 1b; built in Phase 2) |
| O15 | Prepare to make the GitHub repo private, **after** reviewing the repo and its commit history for exposed secrets or sensitive information |

## Not approved (each must be presented separately with staging evidence, effects and rollback)
- **P1:** production migration-history alignment
- **P2:** revoke execute on `limit_saves()`
- **P3:** leaked-password protection

## Mandatory conditions (verbatim summary)
1. No changes to production application code, database schema, migration history, storage policies or settings.
2. Finish the production schema capture before reconstructing migrations.
3. **Checkpoint C1:** present the complete migration mapping + schema comparison; no renaming, splitting or reorganizing of migration files until approved.
4. Production migration history stays unchanged unless P1 is approved.
5. P2 and P3 are presented separately.
6. Test the video verifier on normal, corrupted, incomplete, oversized and unsupported files; no unverified video may become public.
7. Demonstrate the private → public storage operation on staging; use copy–verify–delete if any check fails.
8. Staging data is synthetic only.
9. The production deployment workflow must genuinely require owner approval + a green staging run for the same commit; it is not run against production in Phase 1b.
10. Admin recovery rehearsal on staging: procedure, session revocation and audit evidence documented.
11. Existing marketplace functionality is preserved.

## Out of scope until separately approved
Phase 2, Phase 3, payment integration, promotion packages, business campaigns.
