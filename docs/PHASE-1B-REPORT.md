# Phase 1b Report

**Status: draft, running evidence log.** Evidence is added as each item completes. Finalised at W12 (summary, acceptance criteria B4 1–11, known issues, pending approvals).

---

## 1. CI fix: Edge Functions excluded from the Next.js type check

**Approved by owner:** 19 Nov 2026. Scope: CI configuration only. No application code and no production change.

### 1.1 Failure
| Run | Commit | Push | Result |
|---|---|---|---|
| [43980555556](https://github.com/bigcsp/purple-vendra/actions/runs/43980555556) | `242196a` | W1+W2 | ❌ Type check |
| [43981268000](https://github.com/bigcsp/purple-vendra/actions/runs/43981268000) | `d4f1560` | W3 | ❌ Type check |
| [43982423992](https://github.com/bigcsp/purple-vendra/actions/runs/43982423992) | `884493c` | W5 + C1 evidence | ❌ Type check |

Errors (identical in all three):
```
supabase/functions/storage-cleanup/index.ts(12,30): error TS2307: Cannot find module 'jsr:@supabase/supabase-js@2'
supabase/functions/storage-cleanup/index.ts(16,1): error TS2304: Cannot find name 'Deno'.  (also 18,5 and 19,5)
```
Cause: `tsconfig.json` includes `**/*.ts`, which pulled the Deno-only Edge Function into the Node/Next.js type check.

### 1.2 Fix
Commit **`fc3832ba08ffe2e42b6879a63867e52e9d08aa05`**: `tsconfig.json` `exclude` → `["node_modules", "supabase/functions"]`.

### 1.3 Successful CI run
**Run [44409640426](https://github.com/bigcsp/purple-vendra/actions/runs/44409640426)**, commit `fc3832b`, branch `phase-1b-foundation`, 18 Nov 2026 22:14 UTC, **success** (1m45s).

| Step | Result | Detail |
|---|---|---|
| Install (`npm ci`) | ✅ | |
| Lint (`eslint`) | ✅ | no findings |
| Type check (`next typegen && tsc --noEmit`) | ✅ | 0 errors |
| Build (`next build`) | ✅ | compiled successfully; 48/48 static pages generated |
| Security audit (`npm audit --omit=dev --audit-level=high`) | ✅ | 0 vulnerabilities |

The same five steps also passed locally before the push. Automated tests: none exist yet (W7).

### 1.4 Application build and deployment unaffected
- **Vercel:** the preview deployment for `fc3832b` completed successfully (GitHub commit status "Vercel — Deployment has completed"). The Vercel build runs `next build`, which passed with the same pages generated.
- **App code:** `git diff 884493c fc3832b` changes only `tsconfig.json`. No file under `src/` changed, so the existing marketplace functionality is unchanged.

### 1.5 Edge Function still deployable
- The Supabase CLI bundles functions with its own Deno toolchain and does **not** read the root `tsconfig.json`, so the exclusion can't affect deployment.
- **Deno type check and bundle passed** on GitHub runners (trial run [44515968678](https://github.com/bigcsp/purple-vendra/actions/runs/44515968678), commit `ba64123`, throwaway branch `trial/w8-deno-check`, not merged): `deno check` ✅. `deno bundle` resolved and bundled 58 modules into `storage-cleanup.js` (779 KB) ✅. The Next.js `check` job passed in the same run as a separate job.
- **Production untouched** (read-only check, 19 Nov 2026, under O2a): `storage-cleanup` is still version 1, ACTIVE, with `ezbr_sha256` `1f038da0…f4a5`, identical to the 16 Nov capture in `supabase/functions/storage-cleanup/DEPLOYED.md`. Nothing was deployed anywhere.

### 1.6 W8 requirement: separate Deno check (approved; added when W8 starts)
The job below is added to `.github/workflows/ci.yml` in W8. It is independent of the `check` job: separate runner, no `needs:`, so each passes or fails on its own.

```yaml
  # Supabase Edge Functions run on Deno, not Node, so they are excluded from
  # the Next.js type check (tsconfig.json) and checked here instead.
  edge-functions:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v2
        with:
          deno-version: v2.x
      - name: Deno type check
        run: deno check --node-modules-dir=auto supabase/functions/*/index.ts
      - name: Bundle (proves imports resolve, as a deploy would)
        run: |
          for f in supabase/functions/*/index.ts; do
            deno bundle --node-modules-dir=auto --output "/tmp/$(basename "$(dirname "$f")").js" "$f"
          done
```

Findings from the trial:
- **`--node-modules-dir=auto` is required.** Without it the first trial run ([44515674017](https://github.com/bigcsp/purple-vendra/actions/runs/44515674017)) failed. Because of the root `package.json`, Deno expects npm packages in `node_modules`, and the Supabase runtime types reference `npm:openai`. The flag is used in CI only. A `deno.json` beside the function was deliberately **not** added, because the Supabase CLI reads it at deploy time and adding one would change how the function deploys.
- The glob covers future functions automatically (for example the W10 verifier).

### 1.7 Housekeeping
- The branch `trial/w8-deno-check` still exists on GitHub. Owner to delete it, because the agent proxy can't delete branches. It was never merged.

---

## 2. Checkpoint C1 and Option A (W3/W5)

**Approved by owner:** 19 Nov 2026 (Option A; allowed differences; reconstructed 011; P1 separate). Repo and staging only.

| Item | Evidence |
|---|---|
| Layout applied | Commit `002311a0c0e0325e9a732783a6221e4159e6234d`: 8 renames (content unchanged), 7 files from production's recorded SQL (md5-verified), 4 files moved to `docs/legacy/` |
| Staging reset + rebuild | All 26 files applied (runner HTTP 200, `ok: true`), see `docs/schema/STAGING-REBUILD-2026-11-19.md` |
| Schema comparison | 470/470 present; 453 identical; 17 allowed; **0 unexplained** |
| Real gap closed | `escalate_report()` identical to production |
| Production | Not changed. Read-only queries only (recorded migration SQL, function definitions) |

Acceptance criterion B4.1 (rebuild matches production apart from listed differences) is **met**. B4.2 (mapping) is **met**: every production history row has a repo file with the same version, and 001–011 are marked "applied by hand (P1)".

---

## 3. W6: synthetic seed and anonymizer

**Delivered 19 Nov 2026; awaiting owner review.** Full write-up: `docs/W6-SEED-AND-ANONYMIZER.md`.

| Item | Evidence |
|---|---|
| Seed | `supabase/seed.sql` generated by `supabase/tools/seed/generate_seed.py` (deterministic, `--check` passes). 32 synthetic accounts covering buyers, product sellers, freelancers, home-service pros and creatives; every listing type and status; stories, requests, messages, orders, bookings, reviews |
| Seed loaded on staging | Commit `f44835f`, SHA-256 `6a58e5b2…7c0f`, one transaction, no errors |
| Seed checks | **30/30** pass, including "no seeded text trips the contact-details rule" and "public search hides suspended shops" |
| Guards | Seed refuses a second run (tested), refuses a database with any non-seed user, refuses the production ref |
| Anonymizer | `supabase/tools/anonymize.sql`; **19/19** tests pass, run inside a transaction that is always rolled back; staging unchanged afterwards (checked twice) |
| Housekeeping | Staging Vault runner token deleted. Trial branch: deletion refused by the agent's git proxy, owner to delete |
| Production | Unchanged (read-only check: 7 users, 0 seed accounts, 15 history rows) |

Acceptance criterion B4.4 (staging holds synthetic data only, no production personal data or files): **met**.
