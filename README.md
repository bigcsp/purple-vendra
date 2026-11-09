# Purple Vendra

Nigeria's creative commerce marketplace: **Discover. Create. Promote. Sell.**

Mission: help people turn their skills into visible, discoverable businesses, across three connected marketplaces: Creative, Freelance and Home Services.

Stack: Next.js 16 (App Router, TypeScript) + Tailwind CSS v4 · Supabase (Postgres, Auth with 2FA, Storage) · Nigerian payment provider (₦, added in backend step 7).

## Folder layout

```
purple-vendra/
├── src/
│   ├── app/
│   │   ├── layout.tsx              # fonts, page title
│   │   ├── page.tsx                # homepage (loads marketplaces from Supabase)
│   │   ├── globals.css             # Purple Vendra colours
│   │   ├── actions/auth.ts         # sign up, sign in, sign out, become a seller
│   │   ├── signup/                 # create an account
│   │   ├── login/                  # sign in
│   │   ├── login/verify/           # enter the 6-digit 2FA code
│   │   ├── auth/confirm/route.ts   # the "confirm your email" link lands here
│   │   ├── account/                # your account + "Start selling"
│   │   ├── account/security/       # turn on 2FA (QR code + authenticator app)
│   │   └── sell/                   # seller hub (2FA-confirmed sellers only)
│   ├── components/                 # header, page wrapper, form parts
│   ├── lib/auth.ts                 # who is signed in, their role and 2FA status
│   ├── lib/supabase/               # Supabase clients and keys
│   └── proxy.ts                    # keeps sessions fresh + guards /account and /sell
├── supabase/
│   ├── migrations/                 # database changes, run in order (001 → 006)
│   └── run-in-sql-editor/          # 004 + 005 + 006 in one paste
├── .env.example                    # copy to .env.local and add your keys
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
5. **Run the database migrations, in order.** 001–003 are already done. For 004, 005 and 006, open Supabase → **SQL Editor** → **New query**, paste **all** of `supabase/run-in-sql-editor/004_005_006_combined.sql`, and click **Run**. It runs as one transaction: if anything fails, nothing changes. (The same three files are in `supabase/migrations/` if you'd rather run them one by one.)
   - 004: Creative / Freelance / Home Services marketplaces, professional profiles, verified reviews
   - 005: renames "Fashion & Adé" to "Fashion & Adire"
   - 006: sign-up profiles, roles, and the seller 2FA rule
6. **Start the site:**
   ```bash
   npm run dev
   ```
   Open http://localhost:3000. You should see the purple banner and your 6 categories.

## Sign-in and 2FA settings in Supabase (one-time, step 3)

1. **Authentication → URL Configuration**
   - Site URL: `http://localhost:3000` (change it to your real domain when you go live)
   - Redirect URLs: add `http://localhost:3000/**`
2. **Authentication → Sign In / Providers → Email:** keep **Confirm email** on.
3. **Authentication → Multi-Factor → TOTP (App Authenticator):** make sure it's **enabled** (it is by default).
4. **Recommended: Authentication → Emails → Confirm signup.** Replace the link in the message with:
   ```
   {{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email&next=/account
   ```
   With this link, confirming works even if people open the email on a different phone or browser. The default link also works, but only in the same browser they signed up in.
5. **Supabase's built-in email sender only sends a few emails per hour.** That's fine for testing. Before the pilot, connect your own email sender (SMTP) under **Authentication → Emails → SMTP Settings**.

### Try it

1. `npm run dev`, then go to http://localhost:3000/signup and create an account.
2. Confirm the email, then open **Account** → **Turn on 2FA to start selling**. Scan the QR code with Google Authenticator, Microsoft Authenticator or Authy, and type the code.
3. Click **Start selling**. You land in the **Seller hub**.
4. Sign out and sign in again. You'll be asked for the 6-digit code.

### Make yourself an admin

In the SQL Editor (replace the username):
```sql
update profiles set role = 'admin' where username = 'your_username';
```
Admin powers only work when you're signed in with 2FA.

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
- Every table has Row Level Security on. Anyone can read the marketplaces, categories, seller profiles and approved listings.
- **Seller 2FA rule:** only a seller signed in with a 2FA code (Supabase "aal2") can create, edit or delete listings, listing photos, service areas or working hours, or send quotes. The database checks this, so no bug in the website can skip it.
- Becoming a seller needs a verified authenticator app plus a 2FA-confirmed session.
- People can't change their own role, verified badge, rating or referral code. Sellers can't approve or feature their own listings, and editing an approved listing's title, description, price or category sends it back for review.

## Backend roadmap

1. Database design ✅ · 2. Project setup ✅ · 3. Auth, roles, seller 2FA rule ✅ (built, needs testing) · 4. Storage · 5. Listings & search · 6. Save, cart & alerts · 7. Checkout & escrow · 8. Admin & moderation · 9. Analytics
