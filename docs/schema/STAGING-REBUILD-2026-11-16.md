# Staging clean rebuild, 2026-11-16

- **Project:** `purple-shop-staging` (`fwyviexwregngnqtwcra`), eu-west-2, free plan, created 2026-11-16 (approval O1). Empty at start (0 public tables).
- **Source:** GitHub `bigcsp/purple-vendra` at commit `d4f15603c0cad600ee08172e0990418941f1c421` (branch `phase-1b-foundation`).
- **Why a runner:** the Claude workspace can't reach the staging database directly (network allowlist), and pasting ~290 KB of SQL through the connector risks transcription errors. A temporary, staging-only Edge Function `staging-migration-runner` fetched each file from the pinned commit, checked its SHA-256, and ran it as one transaction (simple query protocol, as the `postgres` role, same as the SQL editor).
- **Safeguards in the runner:** refuses unless `SUPABASE_URL` is the staging project; requires a one-time token stored in staging's Vault; accepts only full commit SHAs and `YYYYMMDDhhmmss_name.sql` file names; stops at the first error.

## Pre-steps on staging (staging only)
1. `create extension if not exists pg_net with schema extensions;` (needed to invoke the runner from SQL)
2. Vault secret `project_url = https://fwyviexwregngnqtwcra.supabase.co` (read by 011's storage-cleanup cron)
3. Vault secret `migration_runner_token` (one-time; deletion pending, see SCHEMA-DIFF-REPORT §8)

## Result: all 22 files applied, HTTP 200, `ok: true`

| File | SHA-256 (verified) | ms |
|---|---|---|
| 20261106000001_initial_schema.sql | 7a32ab94562262447b60415cb1dc0d6be7d97a3082b8a776b84adc1b51c8771a | 236 |
| 20261106000002_public_read_categories.sql | ec6578b3dc672c64dcb349de0123e4cad977c9dc0136fc6a7f4395889e96c3b7 | 7 |
| 20261106000003_home_services.sql | d0942fc866c2055a86f4963a8b7630099b08f41c2c94a25c7d67ab7f3743add4 | 17 |
| 20261106000004_sections_profiles_reviews.sql | 9dade1db9ffac1e16a40210ecb4347d734612c137a5cc19832c03e1acd4f2f33 | 26 |
| 20261106000005_rename_fashion_adire.sql | 725d6f46786c2858c4a01a7d0432d1a1517f06508ece52f3942e6af6ef38bfe4 | 3 |
| 20261109000006_auth_roles_seller_2fa.sql | 331ca1c678d2399fa36cecd20c3bbdee02dea6ba13f429a193d5d74a005f15bb | 32 |
| 20261109000007_security_tidy.sql | b83725b856c3584fbe1b68a3b911cd5ba0382c02763ffc0cf504551acee155a3 | 4 |
| 20261109000008_storage_id_verification.sql | 3a887e41d313abcf3375dfffd014e7603c5c1aa355ae0828232e38b110ca52c8 | 18 |
| 20261109000009_safety_core.sql | 63abbf2e50cde7db66f6d5119530fe52bd3ade7bc21b56b304bcf7595af3297f | 50 |
| 20261109000010_fraud_signals.sql | 9410e65ad2081ececaf907a538a654c64d574299f524e3d08be08a74886f7fdf | 27 |
| 20261109000011_privacy_data_rights.sql *(reconstructed)* | ba53911f78cb25904a9279fe81d9e2357007162ed9fbea37840931a340f87da2 | 207 |
| 20261110000012_vendra_stories.sql | ac02d9f258e43302f02e040d9733946d32f22c9e9e50b21ac4012a6779f68364 | 82 |
| 20261111000013_orders_read_access.sql | af029e5c22cb35b2a43abaf67b1d02b964bcc5786c729b5abfdf6433243aeaa5 | 6 |
| 20261111000014_search_profiles.sql | a39b68513325ec4980c5161bdc47a5b4b3d0bcb64508664393408ff0eb2d4393 | 15 |
| 20261112000015_rename_purple_shop.sql | a8309c98ed9d647d023c17818700e4a3452c77c49cc35c9c0fe83ef1f4cc2d12 | 5 |
| 20261112000016_messaging_no_contact.sql | 3ba42363a510ea562549f27859173c5d5eb953be1e27a0a5ee08fd77d356964e | 25 |
| 20261112000017_faster_blocked_account_rules.sql | ca9338e040084eb1731d109489bd42c43b992ef12a66abf9bc1f7948998bbca4 | 47 |
| 20261112000018_search_everything.sql | 13defa8b7d77e4076693b812792b36026f0b86dc8c4047e1e7ad3c352c2a5302 | 16 |
| 20261112000019_saved_items.sql | 422fb86d02f249418e63264df381e5eb8907ca59cfcc174f7378fa7de6134270 | 10 |
| 20261112000020_purple_requests.sql | 2b8d67701edacc359591c8213cb70101b6b1484fe75e89c7e3d158d31d3623a8 | 36 |
| 20261112000021_seller_records.sql | 90709550fdab3d5ec0f4176e744f3df3a1e9273e7453a7793d323584bb8d092e | 47 |
| 20261114000022_pro_profiles.sql | ab66de711348f4778c79c27bb387cede3c6d9e2061f9158595cf37cc618f811a | 24 |

Total time ≈ 0.9 s. Then compared with production: see `docs/SCHEMA-DIFF-REPORT.md`.
