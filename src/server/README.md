# Backend (`src/server`)

Purple Shop has three parts:

| Part | Where | What it does |
|---|---|---|
| **Website** | `src/app`, `src/components` | Pages and screens people see. Route files in `src/app/api` are one-line doorways into this backend. |
| **Backend** | `src/server` (this folder) | Private server logic. Never sent to a browser. |
| **Database & users** | `supabase/` (Supabase) | Tables, safety rules (RLS), database functions, sign-in and 2FA, file storage, scheduled jobs. |

Shared helpers that are safe in the browser (money formatting, Nigerian states, the contact-details check…) live in `src/lib`.

## Folders

- `db/` — the Supabase connection for server code (uses the signed-in person's own permissions, so database safety rules always apply).
- `auth/` — who is signed in (`getCurrentUser`) and seller checks (`requireSeller`).
- `queries/` — reading data for pages: catalog, search, stories, messages, requests, verification.
- `actions/` — every change to data (Next.js server actions, `"use server"`). Pages and forms call these.
- `api/` — the logic behind `/api/*` routes and the "download my data" export.
- `services/` — payments (Paystack), emails, payouts and other work that needs secret keys. Coming next.

## Rules

1. Every file here except `actions/` starts with `import "server-only"`. If a browser component ever imports one by mistake, the build fails instead of leaking code.
2. Secret keys (Paystack secret, Supabase service key, email keys) are only ever read inside `src/server`.
3. The database stays the final lock: business rules that protect money, privacy or safety are enforced in Supabase functions and rules, and the backend calls them.
4. New public endpoints go under `/api/v1/...` so a future phone app can use the same backend.
