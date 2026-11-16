# Reconstructing migration 011

`production-fn/*.sql` are production's `pg_get_functiondef()` outputs (captured read-only 2026-11-16). Each file's md5 prefix matches the production manifest fingerprint:

| File | md5[:12] | Manifest |
|---|---|---|
| cancel_account_deletion.sql | bd879fd60219 | ✓ |
| export_my_data.sql | 654f52cadbe2 | ✓ |
| process_account_deletion.sql | 4d08b8dff37c | ✓ |
| queue_file_deletion.sql | 4eba5e7c5ad5 | ✓ |
| request_account_deletion.sql | 99e53fbd7ade | ✓ |
| run_privacy_retention.sql | 3b9a9746fed6 | ✓ |

`build011.py` produces `supabase/migrations/20261109000011_privacy_data_rights.sql`. It undoes the later text patches so that replaying 012–022 reproduces production:
- `export_my_data`: removes the blocks added by 012 (stories), 016 (people_you_blocked, and the "Purple Vendra" → "Purple Shop" rename), 021 (seller_record) and 022 (professional_page)
- `process_account_deletion`: removes `'story-media'` from the bucket list (added by 012)

Run: `python3 -I supabase/tools/reconstruct-011/build011.py > supabase/migrations/20261109000011_privacy_data_rights.sql`
