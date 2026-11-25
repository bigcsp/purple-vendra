# Purple Marketing Intelligence

**Status:** **Proposed — awaiting owner review.** Nothing in this document is built or authorised. No events, analytics, AI or messaging were added.
Parent: [`PURPLE-ECOSYSTEM-DIRECTION.md`](PURPLE-ECOSYSTEM-DIRECTION.md) · Classification: [`PURPLE-FEATURE-INTEGRATION-MAP.md`](PURPLE-FEATURE-INTEGRATION-MAP.md) §6

---

## 1. Where it lives

Marketing Intelligence (MI) is a set of tabs and cards **inside Business Studio (`/sell`)**, the existing seller hub. It is not a separate app and gets no new route tree. A planned *Insights* view (ADR-003, S4) is its first surface.

Backend:
- `src/server/queries/insights.ts` (reads)
- SQL functions that aggregate anonymous events
- later, one Edge Function for AI text (`supabase/functions/mi-assist/`)

## 2. Building blocks that already exist [Fact]

| Block | What it gives MI | Gap |
|---|---|---|
| `story_events` + `record_story_event()` + `get_campaign_analytics()` | Anonymous impression, view, share, product-click, shop-visit and add-to-cart counts per story and campaign | Stories only |
| `listing_events` table (`view`, `save`, `cart`, `order`, `share_click`) | The right shape for listing metrics | **Never written by the app**, so there are no listing views today |
| `saves` + `my_listing_save_counts()` | Saves per listing (sellers see counts, never who) | — |
| `follows` + `seller_follow_info()` | Follower counts | No time series |
| `conversations` / `messages` | Enquiries exist | **Not tagged with a source** (which page or promotion the enquiry came from); response time isn't computed |
| `search_queries` + `log_search()` | Anonymous demand: what people search for and how many results they got | No seller-facing view ("people searched *adire bag* 40 times, 3 results") |
| `request_offers` | Quotes and proposals sent and accepted | No conversion view |
| `reviews` + rating trigger | Social proof | Schema only: no completed orders or bookings yet |
| `seller_milestones` / `seller_register` | Onboarding milestones | — |
| Phase 3 A10 `promotion_events` (designed) | Sponsored impressions and actions | Not built |

**What MI can honestly say about a business today: almost nothing beyond stories and saves.** Measurement comes first.

## 3. Staged architecture

| Stage | What | Cost profile | Roadmap |
|---|---|---|---|
| **1. Reliable events** | Write `listing_events`. Add profile and pro-page views, enquiry-started (with source), booking requested/accepted/completed, offer sent/accepted, order completed, repeat customer. All anonymous, using the same pattern as `story_events`. | Database rows only | S2 (already planned as "events model"), widened to the taxonomy in §4 |
| **2. Metrics and rules** | SQL aggregates per seller and per week. Deterministic tips from a rules table (§5). | Cheap: computed on view or nightly with `pg_cron` | S4 Studio Insights + Coach v1 |
| **3. AI assistance** | Plain-language explanations of the seller's **own measured numbers**; draft titles and descriptions; category-specific suggestions | Per-call model cost; capped and cached | S7+ (after ECO-D9) |
| **4. Experiments** | Track whether a tip was accepted and what the metric did afterwards; A/B test of a title or cover photo where traffic allows | Moderate | S8+ |

## 4. Proposed event taxonomy (design only)

One generic, anonymous table or a small family of them. Exact shape to be decided in the S2 plan. Rules: **no user id stored for counting events** (same as `story_events`), plus a session-level dedupe key to resist inflation.

| Event | Division(s) | Source today |
|---|---|---|
| `listing_view`, `listing_save`, `add_to_cart` | Shop, all | `listing_events` enum exists |
| `profile_view` (shop page), `pro_view` (`/pro`) | all | none |
| `portfolio_link_click` (tracked redirect) | Professionals | none (A10 planned) |
| `enquiry_started` (+ `source`: listing / shop / pro / request / promotion) | all | conversations exist, no source |
| `seller_first_reply` (for response time) | all | derivable from `messages` timestamps |
| `quote_sent`, `quote_accepted` | Handy Pro, Professionals | `request_offers` statuses |
| `booking_requested` / `accepted` / `completed` | Handy Pro | `bookings` (schema only) |
| `order_completed`, `repeat_customer` | Shop | needs checkout (S3) |
| `review_left` | all | `reviews` |
| `tip_shown` / `tip_accepted` / `tip_dismissed` | MI | none |

## 5. The five MI parts

### A. Purple Insights
Weekly cards in plain language, for example: "Your bags were viewed 120 times this week, up from 80; 6 people saved one; 2 sent a message." Each card names its time window and its source. **No estimates.** If there's under a configurable minimum of data (e.g. fewer than 20 views), it says so instead of showing percentages.

Metrics by division:
- **Shop:** views → saves → carts → orders, best products, repeat buyers
- **Handy Pro:** profile views → enquiries → quotes → bookings → completed, response time, areas searched
- **Professionals:** pro-page views → link clicks → enquiries → proposals accepted, repeat clients

### B. Marketing Coach (rules first)
A `coach_rules` table (admin-editable, like `platform_settings`). Each rule has:
- division and category scope
- condition (a SQL predicate over the seller's own metrics and listing fields)
- message
- **why it may help**
- **when not to use it**
- a learn-more article

Example rules:

| Condition | Tip |
|---|---|
| Listing has 1 photo | "Listings with more angles let buyers check details; add 3–5 photos." Educational, labelled general guidance. |
| Handy Pro has no `service_areas` | "Customers search by area. Add the areas you cover." |
| Pro page has no portfolio entries | "Add 2–3 recent projects with what you did." |
| High views, no saves or enquiries | "People look but don't act. Check the price is clear and the first photo shows the item." |
| Search demand with few results in the seller's category | "40 searches for *aso-oke cap* this month, 2 listings. If you make these, list one." |
| Reply time over 24h | "Faster replies win more jobs. Turn on notifications." |

Every tip can be **accepted, edited or dismissed**, and the seller can mute a rule.

### C. Category-specific Growth Assistants
These are the same engine with different rule sets and copy per division (Shop, Handy Pro, Professionals), using the division derived in `PURPLE-DIVISIONS-AND-CATEGORIES.md` §3. No generic advice is shown to every business.

### D. Customer Connection Assistant
**Constraint [Fact]:** sellers cannot contact buyers first (owner safety rule, enforced in messaging), and save and cart alerts to sellers stay anonymous.

[Proposal] The assistant works **only through platform-sent messages tied to a completed transaction or an explicit opt-in**:
- **Review request:** the platform sends it once after a completed order or booking. This is already the review rule.
- **Post-job / post-purchase follow-up:** the seller writes a template; the platform sends it once, to customers of a completed transaction who haven't opted out.
- **Restock and maintenance reminders:** only to customers who **opted in** (e.g. "Remind me to service my AC in 6 months"; restock alerts on saved items).
- **Re-engagement:** suggestions for the seller (e.g. "post a story, your followers will see it"). **No bulk messaging of past customers.**
- **Common-question replies:** saved replies inside the existing messaging, used only after the customer writes first.

**Prerequisite, missing today [Fact]:** there's no consent or notification-preference model, and `notifications` is never written. A `notification_preferences` design (per channel, per type, quiet hours, global opt-out) and frequency caps are required **before** any of D ships (ECO-D7). It must also be added to privacy export and deletion.

### E. Campaign Assistant
Built on the Phase 3 promotions and Phase 4 Business Campaigns already planned:
- helps pick a package and target
- drafts creative
- reports **only recorded events**
- paid placements are always labelled **Sponsored** and never shown as verified status, ranking or reputation

## 6. Ethical guardrails: how they're enforced

| Guardrail (brief §6) | Enforcement [Proposal] |
|---|---|
| No invented scarcity, stock or deadlines | "Only N left" is rendered only from `listings.stock`; a countdown only from a real `ends_at` on a deal or promotion. AI prompts get no permission to state counts or dates that aren't in the data. Both are checked in a post-generation validator. |
| No fake reviews or customer numbers | Reviews only from completed jobs (existing `validate_review`). MI shows counts from events only. AI output containing numbers is checked against the input numbers. |
| No deceptive "free" | Deal and free-delivery claims need structured fields. Free-text "free" in titles goes to review (extends the `check_listing_risk` pattern). |
| No false health, nutrition, safety or professional claims | Category-specific risk patterns in listing review; AI refuses to draft such claims; credentials shown only when verified. |
| No discriminatory targeting | Campaign audiences limited to category, state and interest; no protected attributes collected (none are stored today). |
| Privacy and consent | Anonymous events; opt-in reminders; preferences model; export and deletion coverage. |
| Owner in control | Every suggestion has accept / edit / dismiss; nothing is auto-published. |
| Measured vs hypothesis | UI labels: **Measured** (from events) vs **Suggestion** (general guidance). No "this tip increased your sales" without a controlled comparison. |

## 7. AI approach and cost controls (Stage 3, not before ECO-D9)

- **Server-side only**, in one Edge Function. The provider key lives in Supabase secrets and never reaches the browser.
- **On demand, never continuous:** runs when the seller presses "Explain my week" or "Improve this description". The weekly summary is generated once and cached.
- **Inputs are the seller's own aggregated metrics and listing text only.** No customer personal data and no message contents.
- Per-seller monthly allowance in `platform_settings`, a global daily spend cap and a kill switch.
- If data is insufficient, the model is told to say so and to offer labelled general guidance.
- Output passes the validator in §6 before display.
- Human review: admins can sample AI outputs; sellers can report a bad suggestion.

## 8. Dependencies

| MI capability | Needs |
|---|---|
| Insights (any) | Events model (S2) |
| Enquiry metrics | `start_conversation` source tag (planned Phase 3, pull into S2) |
| Shop conversion and repeat buyers | Checkout and escrow (S3) |
| Handy Pro booking funnel | Bookings screens (S6), which need checkout |
| Coach | Insights + `coach_rules` + admin screen (S4) |
| Customer Connection | Notification centre (S2) + preferences and consent (ECO-D7) + completed transactions |
| Campaign Assistant | Phase 3 promotions + Phase 4 campaigns |
| AI | ECO-D9 provider and budget approval, Stage 2 working |
