# Purple Shop

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
│   │   ├── globals.css             # Purple Shop colours
│   │   ├── actions/auth.ts         # sign up, sign in, sign out, become a seller
│   │   ├── signup/                 # create an account
│   │   ├── login/                  # sign in
│   │   ├── login/verify/           # enter the 6-digit 2FA code
│   │   ├── auth/confirm/route.ts   # the "confirm your email" link lands here
│   │   ├── account/                # your account + "Start selling"
│   │   ├── account/security/       # turn on 2FA (QR code + authenticator app)
│   │   ├── sell/                   # seller hub (2FA-confirmed sellers only)
│   │   ├── sell/verify/            # upload ID for verification (private storage)
│   │   ├── sell/listings/          # create, edit, delete listings + photos
│   │   ├── sell/stories/           # Purple Stories: upload, edit, publish, analytics, promote
│   │   ├── shop/[username]/        # public shop page with the Purple Stories gallery
│   │   ├── stories/                # Purple Stories discovery feed (promoted first)
│   │   ├── l/[id]/                 # public listing page
│   │   └── cart/                   # the buyer's cart (checkout comes in step 7)
│   ├── components/                 # header, page wrapper, form parts
│   ├── lib/auth.ts                 # who is signed in, their role and 2FA status
│   ├── lib/upload.ts               # photo shrinking + uploads to Supabase Storage
│   ├── lib/verification.ts         # the seller's ID verification status
│   ├── lib/supabase/               # Supabase clients and keys
│   └── proxy.ts                    # keeps sessions fresh + guards /account and /sell
├── supabase/
│   ├── migrations/                 # database changes, run in order (001 → 012)
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
5. **Database:** migrations 001–008 are already applied to the Purple Vendra Supabase project (004–008 on 9 Nov 2026). For a brand-new Supabase project, run every file in `supabase/migrations/` in order in the SQL Editor (`supabase/run-in-sql-editor/004_005_006_combined.sql` bundles 004–006, then run 007 and 008).
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

## File storage and ID verification (step 4)

Two Supabase Storage buckets, created by migration 008:

| Bucket | Who can see files | What goes in it |
| --- | --- | --- |
| `listing-images` | Everyone (public links) | Listing photos, shrunk to max 1600px WebP before upload |
| `id-documents` | Only the seller and admins | ID photo or PDF, up to 5 MB |

- Files go in a folder named after the owner (`<user id>/...`). Nobody can upload into someone else's folder.
- Only sellers signed in with their 2FA code can upload.
- Sellers can't delete a submitted ID, and they can't approve themselves. Every new upload goes back to "Under review".
- When an ID is approved, the verified badge turns on automatically.

**Approving an ID before the admin screen exists (step 8).** In the SQL Editor, replace the username:
```sql
update seller_verifications set status = 'approved'
where user_id = (select id from profiles where username = 'soseenterprise');
```
To reject, set `status = 'rejected', rejection_reason = 'Photo is blurry'`. To look at the file, go to Storage → `id-documents` → the seller's folder.

## Purple Stories (seller videos) · migration 012, live 11 Nov 2026

Sellers post short videos (any phone video, up to 90 seconds) to their shop page. Before upload, the seller's
browser converts every video to H.264 MP4 at 720p with ffmpeg.wasm, so it plays on every phone and browser. Phones
often record HEVC/H.265, which shows only sound (no picture) on Windows and many Androids. Conversion also shrinks
files (a 5 MB clip becomes about 1 MB). The converter files are copied into `public/ffmpeg` by `npm install`
(`scripts/copy-ffmpeg.mjs`), so run `npm install` after pulling. They can tag up to 6 of
their own listings in each video, so buyers can shop while they watch.

**Sellers** (Seller hub → Purple Stories): upload with a progress bar, preview, an automatic or custom cover
picture, title, description, category and tagged products. Save as a draft or publish, edit, replace the video,
unpublish or delete. 10 new stories a day. **Analytics** shows views, engagement, likes, comments, shares,
product clicks, shop visits, add-to-carts and sales from videos (7, 30 or 90 days). **Promote** creates a campaign:
pick a story, an audience (categories and/or states), 1–30 days and a budget (₦1,000–₦1,000,000).

**Buyers**: watch on the shop page or at `/stories`, then play/pause, like, comment, share, follow, tap a product,
add it to their cart, visit the shop or report the video. Promoted stories show first, with a "Promoted" label,
to the audience the seller chose.

**Campaign payments (until checkout exists).** New campaigns wait as "Awaiting payment". After the seller pays you,
activate the campaign in the Supabase SQL Editor:
```sql
-- see who's waiting
select c.id, p.username, c.budget_kobo / 100 as naira, c.duration_days, c.created_at
from story_campaigns c join profiles p on p.id = c.seller_id where c.status = 'awaiting_payment';
-- payment received → runs for its full duration from now
update story_campaigns set status = 'active', payment_reference = 'BANK-REF-123',
  starts_at = now(), ends_at = now() + make_interval(days => duration_days)
where id = '<campaign id>' and status = 'awaiting_payment';
-- or reject it
update story_campaigns set status = 'rejected', admin_note = 'Reason' where id = '<campaign id>';
```
Finished campaigns close themselves every hour (`story-campaigns-complete` cron job).

**Approving a listing (until the admin screen in step 8):**
```sql
update listings set status = 'approved' where id = '<listing id>';
```

**Moderation.** Reports work on videos too. When 3 established users report a video, it's hidden automatically and
a high-priority flag is raised. Phone numbers or "pay me outside" text in titles, descriptions and comments raise a
flag. To hide or remove a video yourself:
`update story_videos set status = 'removed', moderation_note = 'Reason' where id = '<story id>';`

**Privacy.** Analytics events never store who did them. Your data export includes stories, likes, comments and
campaigns. Deleting an account removes the person's stories, likes and comments, and queues their video files for
the nightly storage cleanup.

## Search, categories & shop profiles (step 5) · migrations 013–014, live 11 Nov 2026

- **Search** (`/search`, and the search box in the header): finds approved listings by title and description. It
  tolerates typos ("agbda" finds "agbada"), matches shops by name, and filters by category, state (including the
  areas a seller serves), type and price, with 5 ways to sort. Featured listings show first. Every search is logged
  anonymously in `search_queries` for the weekly demand insights.
- **Category pages** (`/c/fashion-adire`, …): the homepage category cards open them. Each shows that category's
  Purple Stories plus all its listings, with the same filters.
- **Shop profile** (Seller hub → Edit shop profile, `/sell/profile`): logo or photo, business name, headline,
  about, state/city, years of experience, a "taking orders" switch, working hours and service areas. All of it shows
  on the shop page.
- **Privacy pages** (restored): `/account/privacy` lets people download their data and delete or cancel deleting
  their account. `/privacy` is a draft policy that needs a lawyer's review and a contact email before launch.
- **Book and Message buttons** come with step 6 (messaging and bookings).

## Professional pages (Purple Pro, step 1) · migration 022

Sellers get a shareable page at `/pro/<username>`, set up from Seller hub → **Professional page** (`/sell/pro`).

- **Two page types:** *Professional Profile* (career profile) or *My Creative Space* (visual, cover-led). Sellers can switch at any time without losing anything.
- **What it shows:** cover image, photo, name, headline, about, location, availability, skills, languages, experience,
  education, certifications, achievements, live service listings, working hours, service areas and trust details.
  Photo, name, headline, about, location, hours and areas are shared with the shop profile, so they're edited once.
- **Private by default.** The owner can preview a private page; everyone else gets "not found" until it's made public.
- **Rules in the database:** only 2FA sellers can edit, phone numbers / "pay me outside" text is refused, 25 items per
  section, 20 skills, 10 languages, covers must be the seller's own upload, and nobody can give themselves Premium.
- **Plans:** every page is free. Premium (extra themes, unlimited projects, personal website links, badge) is switched on
  by hand until payments go live:
  ```sql
  update profiles set plan = 'premium', plan_expires_at = now() + interval '30 days' where username = 'their_username';
  ```

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

1. Database design ✅ · 2. Project setup ✅ · 3. Auth, roles, seller 2FA rule ✅ · 4. Storage & ID verification ✅ (live; needs a browser test) · Purple Stories ✅ (live; needs a browser test) · 5. Listings, search, categories & profiles ✅ · 6. Save, cart & alerts · 7. Checkout & escrow · 8. Admin & moderation · 9. Analytics
