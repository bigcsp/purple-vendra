# Purple Divisions & Categories

**Status:** **Proposed — awaiting owner review.** Planning only; no taxonomy, schema or onboarding change has been made.
Parent: [`PURPLE-ECOSYSTEM-DIRECTION.md`](PURPLE-ECOSYSTEM-DIRECTION.md) · Decisions: [`decisions/ADR-004-purple-ecosystem-direction.md`](decisions/ADR-004-purple-ecosystem-direction.md)

---

## 1. What exists today [Fact]

Three independent axes already describe every listing and seller:

**a) Sections → categories** (migrations `…000004_sections_profiles_reviews`, `…000003_home_services`, `…000005_rename_fashion_adire`)

| Section (`sections`) | Categories (`categories.section_id`) |
|---|---|
| `creative`: Creative Marketplace | `fashion-adire` Fashion & Adire · `art-crafts` Art & Crafts · `digital-design` Digital & Design · `photo-video-talent` Photo, Video & Talent |
| `freelance`: Freelance Marketplace | `tech-freelance` Tech & Freelance |
| `home-services`: Home Services Marketplace | `home-services` Home Services & Repairs |

The homepage shows one block per section (`src/app/page.tsx` reads `sections`). The listing form labels categories `section · category`.

**b) Listing type** (`listing_type` enum, on each listing): `product`, `service`, `talent` (modelling, make-up artistry, performing).

**c) Delivery mode** (`delivery_mode`): `pickup`, `delivery`, `digital`, `in_person_service`, `remote_service`.

Other relevant facts:
- **Role** is per account: `buyer`, `seller` or `admin`. `become_seller()` needs verified TOTP 2FA. There's **no business-type field** on the account.
- **Sign-up** asks the intent: "shop", "sell" or "both". It doesn't store it as a business type, and it doesn't ask what is sold.
- **Pro profile** `pro_mode`: `professional` or `creative_space` (migration `pro_profiles`).
- **Handy-style fields** exist on the seller profile and are editable in `/sell/profile`:
  - `service_areas` (state + city/LGA)
  - `working_hours`
  - `is_available` ("Taking orders")
  - `business_name`, `headline`, `years_experience`
- **Home-services safety rule:** a listing in `home-services` can't be submitted until the seller's ID verification is approved (`enforce_home_service_verification`).
- **Quotes:** `listings.quote_on_request` ("Get a quote") plus `request_offers` (up to 10 offers per buyer request).

## 2. The mismatch

Today's **sections** split by *industry* (creative, freelance, home). The new **divisions** split by *what is being sold* (goods, hands-on work, professional work). So the axes cross:

| Example listing | Section today | Division under the new direction |
|---|---|---|
| Adire fabric, painting, printed tote | Creative | **Purple Shop** |
| Logo design, Canva templates (digital download) | Creative (Digital & Design) | **Purple Shop** if it's a ready-made product; **Purple Professionals** if it's commissioned work |
| Wedding photography, video editing | Creative (Photo, Video & Talent) | **Purple Professionals** |
| Make-up artist, model, performer (`talent`) | Creative | **Purple Professionals** by default (ECO-D4: an MUA travelling to clients could be Handy Pro) |
| Web developer, virtual assistant | Freelance | **Purple Professionals** |
| Plumber, AC/generator repair, cleaner | Home Services | **Purple Handy Pro** |

**Conclusion:** the existing `sections` table can't be renamed to the three divisions without misfiling the Creative services. However, **`listing_type` plus category already tells us the division of every listing**, with no new data.

## 3. Proposed division model

### Option A: derive the division (recommended) [Proposal]
The division is **computed** from data that already exists:

```
division(listing) =
  'handy_pro'      if category.section = 'home-services'
  'shop'           if listing.type = 'product'
  'professionals'  otherwise            -- service or talent outside home services
```

- Later this would be one SQL function or view plus one TypeScript helper. There's no new column on listings and no backfill.
- A seller's divisions = the set of divisions of their live listings, plus any division they chose during onboarding (Option A+ below).
- Existing URLs, sections, categories and search behave exactly as today.
- Display: division badges on search results and listing cards; division landing pages that filter the existing catalogue.

### Option A+: add a small seller preference (later, with onboarding)
A `seller_divisions (seller_id, division, created_at)` join table records which divisions a business **chose** during onboarding. It's used only to pick the onboarding steps, the Studio layout and the Growth Assistant. It never decides permissions, which stay with `can_post()` and the category rules. That makes it multi-valued from day one.

### Option B: re-parent the taxonomy (not now)
Introduce a `divisions` table above sections, or replace sections with divisions and re-file categories. This is cleaner long-term **only if** the categories are split by division first (e.g. "Digital & Design products" vs "Design services"). It touches the homepage, listing form, search filters and the seed, which is a schema change and a journey change. Revisit at S6 if Option A proves limiting.

### Option C: a separate "business" entity per division (rejected)
Duplicates identity, messaging, verification and reviews. It goes against the brief (§3) and against ADR-003.

## 4. Multi-division businesses

- Already supported at listing level [Fact]: one seller can hold product and service listings.
- Rules that should stay **per listing, not per account**:
  - the home-services ID requirement (already per listing)
  - stock and delivery rules (products)
  - booking rules (Handy Pro)
- Rules that stay **per account**: identity, 2FA, account status, verification badge, ratings (aggregate), Premium plan.
- Open question **ECO-D5:** whether ratings should also be shown **per division** (e.g. a seller who sells fabric and does tailoring). [Proposal] Keep one aggregate rating for v1. Reviews already link to the order or booking, so per-division rating can be computed later without a schema change.

## 5. Category taxonomy

### 5.1 Keep the existing six
All six stay, with unchanged slugs (URLs `/c/[slug]` depend on them).

### 5.2 Candidate categories named in the brief (all new, not added)

| Division | Candidate categories | Notes and risks |
|---|---|---|
| Shop | Electronics & gadgets · Beauty & personal care · Home & furniture · Food & groceries · General merchandise | **Scope change.** The launch scope is creative commerce, Nigeria-only (owner decision). Food and groceries bring perishables, delivery windows and NAFDAC-registration claims. Beauty and health products bring ingredient and claim rules. Electronics brings warranty and counterfeit risk. Each needs its own listing rules and moderation checks before it opens (ECO-D3). |
| Handy Pro | Split `home-services` into sub-categories: Plumbing · Electrical · AC & generator · Carpentry · Painting & tiling · Cleaning & fumigation · Appliance repair · Auto mechanic · Building & masonry | The migration comment already lists most of these. **Mechanics** are new: work is often at the customer's location or a workshop, so the service address rules need checking. |
| Professionals | Split `tech-freelance`: Software & web · Design · Writing & translation · Digital marketing · Video & photo · Virtual assistance · Consulting | Photo/video currently sits in Creative; see §2. |

[Proposal] Sub-categories as rows under the existing categories (a `parent_id`), not new top-level categories. That keeps existing slugs, filters and the seed intact. Do this at S6 together with the division onboarding, not before.

## 6. Onboarding implications

**Today [Fact]:** sign-up intent shop/sell/both → `/welcome` → `/sell` hub → turn on 2FA → `become_seller()` → create listing (choose type and category) → optional ID verification (required for home services).

**Proposed future flow** (no change now; ECO-D6):
1. **Registration stays as it is.** No division question at sign-up. That keeps sign-up fast and changes no auth flow.
2. **First visit to Business Studio** asks: *What do you offer?*
   - I sell products → **Shop**
   - I offer hands-on or local services → **Handy Pro**
   - I offer freelance, tech, creative or professional services → **Professionals**
   - The answer is multi-select and can be changed later.
3. **Adaptive checklist** in the existing seller-progress component:

| Shop | Handy Pro | Professionals |
|---|---|---|
| Shop profile, first product, photos, stock, delivery mode | **ID verification (required)**, service areas, working hours, first service (fixed price or "Get a quote"), availability | Pro profile (`/pro`), skills, portfolio entries, first service package, availability |

4. 2FA (`can_post()`) stays required for everyone before posting.

## 7. Verification by division [Proposal, ECO-D8]

| Division | Required before listing | Optional trust signals |
|---|---|---|
| Shop | 2FA (today) | ID verification badge; category-specific checks for regulated goods if ECO-D3 opens them |
| Handy Pro | 2FA + **approved ID** (today, enforced) | Trade certificate upload (future), completed-job count, before-and-after photos |
| Professionals | 2FA (today) | ID verification badge, portfolio links (tracked), verified client reviews |

Credentials are shown only once they've been verified (brief §6: never invent credentials).
