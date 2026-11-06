# Purple Vendra

Nigeria's creative commerce marketplace: **Discover. Create. Promote. Sell.**

Stack: Next.js 16 (App Router, TypeScript) + Tailwind CSS v4 · Supabase (Postgres, Auth with 2FA, Storage) · Nigerian payment provider (₦, added in backend step 7).

## Folder layout

```
purple-vendra/
├── src/
│   ├── app/
│   │   ├── layout.tsx          # fonts, page title
│   │   ├── page.tsx            # homepage (loads categories from Supabase)
│   │   └── globals.css         # Purple Vendra colours
│   ├── lib/supabase/
│   │   ├── client.ts           # Supabase in the browser
│   │   ├── server.ts           # Supabase on the server (user + public clients)
│   │   └── env.ts              # reads the keys from .env.local
│   └── proxy.ts                # keeps login sessions fresh on every request
├── supabase/migrations/        # database changes, run in order
│   ├── 20261106000001_initial_schema.sql        # ✅ already run
│   ├── 20261106000002_public_read_categories.sql  # run this next
│   └── 20261106000003_home_services.sql           # then this
├── .env.example                # copy to .env.local and add your keys
└── package.json
```

## First-time setup (Windows)

1. **Install tools** (skip any you have): [Node.js LTS](https://nodejs.org), [Git](https://git-scm.com), [VS Code](https://code.visualstudio.com).
2. **Open the folder:** VS Code → File → Open Folder → choose `purple-vendra`.
3. **Install packages:** Terminal → New Terminal, then run:
   ```bash
   npm install
   ```
4. **Add your Supabase keys:** copy `.env.example`, rename the copy to `.env.local`, and fill in:
   - `NEXT_PUBLIC_SUPABASE_URL` — your Project URL
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` — the publishable (or anon) key

   Both are in Supabase → **Connect** button, or Project Settings → API Keys. **Never** use the `service_role` / secret key here.
5. **Run the new migrations, in order:** Supabase → SQL Editor → New query → paste the file → Run:
   - `20261106000002_public_read_categories.sql` (lets the homepage read the category list)
   - `20261106000003_home_services.sql` (Home Services & Repairs category, bookings, service areas)
6. **Start the site:**
   ```bash
   npm run dev
   ```
   Open http://localhost:3000. You should see the purple banner and your 6 categories.

## Push to GitHub

The folder is already a Git repository with a first commit.

**Easiest (VS Code):** click the **Source Control** icon in the left bar → **Publish Branch** → sign in to GitHub if asked → choose **Private repository** → name it `purple-vendra`. VS Code creates the repo and pushes.

**Or with commands:** create an empty private repo named `purple-vendra` on github.com (no README), then:
```bash
git remote add origin https://github.com/<your-username>/purple-vendra.git
git push -u origin main
```

`.env.local` is ignored by Git, so your keys are never pushed.

## Rules built into the database

- Money is stored in kobo (₦1 = 100 kobo) as whole numbers.
- An order's seller payout must equal subtotal + delivery − platform fee; the reseller's 3% always comes out of the platform fee.
- Save/cart alerts, search logs and analytics events never store who did the action.
- Every table has Row Level Security on. Only the categories list is publicly readable so far; all other access rules come in backend step 3.

## Backend roadmap

1. Database design ✅ · 2. Project setup ✅ · 3. Auth, roles, seller 2FA rule · 4. Storage · 5. Listings & search · 6. Save, cart & alerts · 7. Checkout & escrow · 8. Admin & moderation · 9. Analytics
