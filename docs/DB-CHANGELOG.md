# Database change log

Every change to a Purple Shop database (staging or production) gets an entry here. Production entries need an owner approval reference.

| Date | Environment | Change | Migration / command | Why | Risk | Rollback | Staging result | Approval |
|---|---|---|---|---|---|---|---|---|
| 2026-11-06 → 2026-11-14 | production | Migrations 001–011 applied by hand in the SQL editor; 012–022 via migration tool (15 history rows) | see `docs/MIGRATION-MAPPING.md` | Pre-freeze history, recorded for completeness | n/a | n/a | n/a | pre-freeze |
| 2026-11-16 | production | **Change freeze starts** (ADR-001). Read-only catalog capture only. | — | Phase 1b | none | n/a | n/a | ADR-002 |
