# storage-cleanup: deployed state (captured read-only 2026-11-16)

| Field | Production value |
|---|---|
| Project | nozxxxldfthbwhjwbsmy |
| Function id | 9b4024a5-2a39-4623-b897-62878afac7f4 |
| Version | 1 |
| Status | ACTIVE |
| verify_jwt | **false** (publicly callable; see P4) |
| Entrypoint | index.ts |
| ezbr_sha256 (Supabase bundle hash) | 1f038da0178771a251c83ac2fa43d4655402ab24a583ff46a251c893af4af4a5 |

`index.ts` here is the source returned by the Supabase API (transcribed; content identical). Called nightly by cron job `storage-cleanup` (`45 2 * * *`).
