# Staging clean rebuild after C1 (Option A), 2026-11-19

- **Approval:** checkpoint C1 approved by the owner on 19 Nov 2026 (Option A, the 23 allowed differences, reconstructed 011; P1 stays separate).
- **Project:** `purple-shop-staging` (`fwyviexwregngnqtwcra`). **Staging only. Production was not changed.**
- **Source:** commit `002311a0c0e0325e9a732783a6221e4159e6234d` (branch `phase-1b-foundation`), 26 migration files.
- **Runner:** the same temporary `staging-migration-runner` as 16 Nov (see `STAGING-REBUILD-2026-11-16.md`): fetches each file from the pinned commit, checks SHA-256, runs it as one transaction, stops on first error.

## 1. Reset (staging only, one transaction)
Guarded so it only runs on the project that holds the staging runner token. It removed everything the 16 Nov build created:
- the 4 cron jobs (unscheduled), then `pg_cron`
- the `auth.users` trigger `on_auth_user_created`
- 14 storage policies and the 3 (empty) buckets
- schema `private`
- every table, view, function, type and sequence in `public`, then `pg_trgm`

Kept: schema `public` with its default privileges (6 `pg_default_acl` rows, checked), `pg_net` and the Vault secrets (pre-steps of the 16 Nov build). After the reset, `public` had 0 relations, 0 functions and 0 types; there were 0 buckets and 0 storage policies. Staging held no users or files (0 / 0).

## 2. Rebuild: all 26 files applied, HTTP 200, `ok: true`

| File | SHA-256 (verified by runner) | ms |
|---|---|---|
| 20261106000001_initial_schema.sql | 7a32ab94562262447b60415cb1dc0d6be7d97a3082b8a776b84adc1b51c8771a | 273 |
| 20261106000002_public_read_categories.sql | ec6578b3dc672c64dcb349de0123e4cad977c9dc0136fc6a7f4395889e96c3b7 | 4 |
| 20261106000003_home_services.sql | d0942fc866c2055a86f4963a8b7630099b08f41c2c94a25c7d67ab7f3743add4 | 16 |
| 20261106000004_sections_profiles_reviews.sql | 9dade1db9ffac1e16a40210ecb4347d734612c137a5cc19832c03e1acd4f2f33 | 26 |
| 20261106000005_rename_fashion_adire.sql | 725d6f46786c2858c4a01a7d0432d1a1517f06508ece52f3942e6af6ef38bfe4 | 4 |
| 20261109000006_auth_roles_seller_2fa.sql | 331ca1c678d2399fa36cecd20c3bbdee02dea6ba13f429a193d5d74a005f15bb | 45 |
| 20261109000007_security_tidy.sql | b83725b856c3584fbe1b68a3b911cd5ba0382c02763ffc0cf504551acee155a3 | 3 |
| 20261109000008_storage_id_verification.sql | 3a887e41d313abcf3375dfffd014e7603c5c1aa355ae0828232e38b110ca52c8 | 13 |
| 20261109000009_safety_core.sql | 63abbf2e50cde7db66f6d5119530fe52bd3ade7bc21b56b304bcf7595af3297f | 44 |
| 20261109000010_fraud_signals.sql | 9410e65ad2081ececaf907a538a654c64d574299f524e3d08be08a74886f7fdf | 24 |
| 20261109000011_privacy_data_rights.sql | ba53911f78cb25904a9279fe81d9e2357007162ed9fbea37840931a340f87da2 | 202 |
| 20261111114059_vendra_stories.sql | ac02d9f258e43302f02e040d9733946d32f22c9e9e50b21ac4012a6779f68364 | 104 |
| 20261111131447_orders_read_access.sql | af029e5c22cb35b2a43abaf67b1d02b964bcc5786c729b5abfdf6433243aeaa5 | 6 |
| 20261111141906_search_profiles.sql | 37d4cc1268fa2e357039a88cbbcd5d1fe5d467c3f53b57322d0e84d2baec22cb | 21 |
| 20261111141945_search_word_similarity.sql | a8ea8b5692ac881e1ee47947e31bf9cd3831d31a397059a7aea49eb02fc4c950 | 7 |
| 20261112153210_rename_purple_shop.sql | a8309c98ed9d647d023c17818700e4a3452c77c49cc35c9c0fe83ef1f4cc2d12 | 3 |
| 20261112154821_messaging_no_contact.sql | b9fb2ac3b5c17d8ffedc76a5103c3f8e7ce73c15303e93c56638df13a4edb3a7 | 29 |
| 20261112154910_messaging_lock_block_helper.sql | f8b216b643a3b43ee08fc8897ab081a63edb253869acba35a38df5f7ecbeea64 | 3 |
| 20261112161210_faster_blocked_account_rules.sql | ca9338e040084eb1731d109489bd42c43b992ef12a66abf9bc1f7948998bbca4 | 59 |
| 20261112161822_search_everything.sql | 13defa8b7d77e4076693b812792b36026f0b86dc8c4047e1e7ad3c352c2a5302 | 21 |
| 20261112162702_saved_items.sql | 422fb86d02f249418e63264df381e5eb8907ca59cfcc174f7378fa7de6134270 | 6 |
| 20261112181843_purple_requests.sql | e1d0e981e7eecd4390eca083e62b170d27b8676d7aeaaf2e5a82ca9ff6a84a40 | 45 |
| 20261112181859_request_reports_keep_buyer_hidden.sql | 297f8b98706a9817c3a4be004d2dd590a7b4f5e561bb11b96efd6844aeee5fe0 | 4 |
| 20261112181916_request_reports_escalation.sql | e515cd6943bf44836dedb1b12a26f62eeacf28ab3d999cb1442989957e986010 | 3 |
| 20261112230307_seller_records.sql | 90709550fdab3d5ec0f4176e744f3df3a1e9273e7453a7793d323584bb8d092e | 47 |
| 20261114125544_pro_profiles.sql | ab66de711348f4778c79c27bb387cede3c6d9e2061f9158595cf37cc618f811a | 37 |

The 11 files that were renamed but not changed keep exactly the SHA-256 they had on 16 Nov.

The 7 production-copied files hold production's recorded SQL verbatim. Each has a 4-line provenance header; the md5 of the SQL below the header equals md5 of `statements` in production's `supabase_migrations.schema_migrations` (checked read-only on 2026-11-19).

## 3. Comparison with production (manifest of 2026-11-16, 470 objects)
Method: `supabase/tools/schema-manifest.sql` run on staging and compared in two steps:
1. a checksum (md5 of all `ident<TAB>fingerprint` lines, C-collation order) per object kind, compared with the same checksum computed from `production-manifest-2026-11-16.tsv`;
2. for the kinds that differed, row-level comparison against production's fingerprints.

| Kind | Objects | Result |
|---|---|---|
| bucket | 3 | identical |
| cron | 4 | identical |
| ext_trigger | 1 | identical |
| extension | 8 | identical |
| policy | 235 | identical |
| sequence | 10 | identical |
| table | 47 | identical (columns, constraints, indexes, triggers, RLS, grants) |
| type | 29 | identical |
| function | 125 | **109 identical**, 16 cosmetic (below) |
| extension_version | 8 | 7 identical; `supabase_vault` 0.3.2 vs 0.3.1 (platform) |

**Totals: 470/470 present on both sides, 453 identical, 17 allowed, 0 unexplained.**

The 16 cosmetic function differences were re-checked against production read-only with the same normalizations as on 16 Nov:
- **CRLF only (6):** `enforce_home_service_verification`, `protect_review`, `refresh_seller_rating`, `set_updated_at`, `validate_review`, `protect_report`. md5 after CRLF→LF is identical. `protect_report` was listed as comment-only on 16 Nov; it is now built from production's own SQL, so its only remaining difference is production's CRLF line endings.
- **Comments/whitespace only (10):** `track_seller_profile`, `check_listing_risk`, `check_message_risk`, `guard_pro_fields`, `protect_listing_fields`, `protect_profile_fields`, `protect_seller_verification`, `protect_story_video`, `record_story_event`, `search_suggest`. md5 after removing `--` comments and whitespace is identical.

**Now identical (were differences on 16 Nov):** `escalate_report()` (the one real gap, closed by file `20261112181916_request_reports_escalation.sql`), and the comment-only differences in `accept_offer`, `block_contact_details`, `close_request`, `contact_problem`, `log_search`, `send_offer`. These 6 rows were removed from `allowed-differences.tsv`, which now has 17 rows.
