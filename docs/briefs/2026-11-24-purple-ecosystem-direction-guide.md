# PURPLE ECOSYSTEM — PRODUCT DIRECTION & SMART MARKETING PROJECT GUIDE

**Document type:** Product direction and architectural guidance  
**Status:** Proposed direction — documentation and planning only  
**Applies to:** Existing Purple Shop codebase  
**Primary rule:** Redirect the product vision without disrupting, replacing, or prematurely modifying the existing implementation.

---

## 1. Product Vision

Purple should grow into a connected business ecosystem that helps people **discover businesses, connect with customers, win work, improve customer relationships, and grow sustainably**.

The goal is not simply to compete with other marketplaces or become the biggest catalogue. The goal is to provide a genuinely useful experience for customers and practical business-growth support for every seller and service provider.

Purple should help:
- Product sellers attract customers and improve sales.
- Handy professionals get discovered, receive enquiries and bookings, and build trust.
- Freelancers and other professionals showcase their skills, find clients and win projects.
- Customers find products, services and skilled people through one connected experience.

The platform should be helpful to businesses even when they do not pay for advertising or promotions. Paid promotion may add visibility, but essential marketplace participation and useful core business guidance must not depend on paying.

## 2. Brand and Marketplace Structure

Use one parent ecosystem: **Purple**.

Organise it into three specialised divisions:

### A. Purple Shop — Products & Commerce
For businesses selling physical products, including fashion, electronics, food, beauty, groceries, furniture and general merchandise.

Typical needs:
- Storefronts and product catalogues.
- Product images, videos and stories.
- Inventory, orders and delivery information.
- Product pricing, bundles and promotions.
- Product reviews and repeat-purchase tools.
- Sales and product-performance insights.

### B. Purple Handy Pro — Hands-on and Local Services
For plumbers, electricians, mechanics, carpenters, painters, cleaners, AC technicians, appliance repairers, builders and other practical service providers.

Typical needs:
- Professional profiles and service catalogues.
- Service areas and location-based discovery.
- Availability, appointment requests and bookings.
- Customer problem descriptions, photos and videos.
- Quotations, job status and completion records.
- Before-and-after portfolios, verification and reviews.
- Repeat-service and maintenance reminders.

### C. Purple Professionals — Freelance, Technology and Creative Services
For software developers, designers, photographers, writers, digital marketers, consultants, video editors, virtual assistants, creative professionals and other independent specialists.

Typical needs:
- Professional profiles and portfolios.
- Skills, experience and service descriptions.
- Service packages, indicative pricing and consultations.
- Project requests, proposals and quotations.
- Client communication and project status.
- Testimonials, reviews and client retention tools.

Use **Purple Professionals** as the proposed division name rather than limiting the division to “Purple Freelancing” or “Purple Tech”, so it can accommodate a wider range of professional services.

## 3. One Connected Platform, Not Three Separate Applications

The three divisions should have specialised catalogues, onboarding, dashboards and customer journeys, but should share the existing Purple platform infrastructure wherever appropriate.

Shared capabilities may include:
- One account and identity system.
- Messaging and notifications.
- Customer relationship and review systems.
- Search and discovery infrastructure.
- Promotions and campaign infrastructure.
- Analytics and reporting foundations.
- Payment infrastructure, when separately approved.
- Trust, safety, moderation and support processes.

A business may need to operate in more than one division. Do not assume that a user or business must be permanently locked into one category. Assess how multiple business types can be supported safely within the current data model.

Do not create three separate apps, duplicate shared systems, or redesign the current architecture without evidence that a change is necessary.

## 4. Onboarding and Category Selection

The intended future experience should ask a new business what it offers:

1. I sell products — Purple Shop.
2. I offer hands-on or local services — Purple Handy Pro.
3. I offer freelance, technology, creative or professional services — Purple Professionals.

The onboarding fields should adapt to the selected business type. For example:
- Product sellers need product, inventory and delivery information.
- Handy Pros need services, service areas, availability and job information.
- Professionals need skills, portfolios, packages and project availability.

Allow multiple divisions where a business genuinely offers multiple types of products or services, subject to a coherent account and permissions model.

This is a proposed direction. First map it against existing onboarding and account functionality. Do not change registration flows in this planning phase.

## 5. Purple Marketing Intelligence

Introduce **Purple Marketing Intelligence** as a central capability within the existing seller/business experience, not as a separate application.

Its purpose is to help every business understand performance, improve presentation, connect with customers and identify practical growth opportunities.

It should eventually include:

### A. Purple Insights
Explain business performance in understandable language:
- Views, enquiries, orders, bookings and projects.
- Conversion rates and response times.
- Best-performing products or services.
- New and returning customers.
- Customer reviews and engagement.
- Promotion and campaign performance.

### B. Marketing Coach
Teach businesses useful marketing principles and recommend relevant actions:
- Product/service positioning and clear benefit-led descriptions.
- Better titles, photographs, videos and portfolio presentation.
- Social proof through genuine reviews and testimonials.
- Bundling and complementary offers.
- Cross-selling and appropriate upselling.
- Customer retention and follow-up.
- Storytelling and business introductions.
- Pricing presentation and transparent offers.
- Genuine limited-time or limited-availability promotions.
- Seasonal and category-specific campaigns.

The coach must explain why a suggestion may help, when to use it, and any conditions or risks.

### C. Category-Specific Growth Assistants
Use one shared intelligence foundation with different guidance for each division:

- **Purple Shop:** product presentation, inventory-aware offers, bundles, product conversion and repeat purchases.
- **Purple Handy Pro:** local discovery, trust signals, service descriptions, availability, enquiry-to-booking conversion, quotations and maintenance reminders.
- **Purple Professionals:** portfolio quality, skill positioning, service packages, proposals, client enquiries, testimonials and repeat clients.

Do not give every business the same generic marketing advice.

### D. Customer Connection Assistant
Help businesses build lasting customer relationships:
- Thoughtful post-purchase or post-job follow-ups.
- Review requests after completed transactions.
- Restock and relevant service reminders.
- Responses to common customer questions.
- Re-engagement suggestions for inactive customers.
- Customer feedback and service-improvement insights.

Communications must respect customer consent, privacy and notification preferences. Avoid spam.

### E. Campaign Assistant
Help businesses create clear, relevant campaigns and measure their results. Paid promotions must be clearly labelled and must not be confused with organic ranking, verified quality or reputation.

## 6. Marketing Principles and Ethical Guardrails

The system may teach and recommend proven marketing approaches, including:

- **Scarcity:** communicate genuinely limited stock, appointment slots or offer deadlines only when verified.
- **Value framing:** present the real benefits and value of an offer clearly.
- **Bundling:** suggest useful combinations of products or services.
- **Social proof:** highlight authentic reviews, testimonials and completed work.
- **Personalisation:** make relevant recommendations based on legitimate customer interests and activity.
- **Retention:** encourage repeat business through useful follow-up and service.
- **Cross-selling and upselling:** suggest genuinely complementary or more suitable options.
- **Storytelling:** help businesses explain who they are and the value they provide.
- **Experimentation:** test alternative descriptions, images or offers where feasible.

Strict requirements:
- Never invent scarcity, stock counts, deadlines, reviews, customer numbers, credentials or performance claims.
- Never make deceptive “free” claims or hide material conditions.
- Never encourage false, unsupported or unlawful product, nutrition, health, safety or professional claims.
- Do not recommend discriminatory targeting or manipulative pressure.
- Respect customer privacy, consent and applicable laws.
- Make recommendations explainable and allow the business owner to accept, edit or dismiss them.
- Distinguish measured results from hypotheses. Do not claim a suggestion caused a sales increase without adequate evidence.

## 7. Smart Technology Approach

Use a staged, cost-conscious architecture:

1. **Reliable event tracking first:** define and collect trustworthy events such as product views, profile views, enquiries, add-to-cart actions, purchases, booking requests, completed jobs, proposals and repeat transactions.
2. **Analytics and rules second:** calculate transparent metrics and use deterministic rules for straightforward suggestions.
3. **AI assistance third:** use AI to interpret available business context, explain insights, draft descriptions and generate category-specific suggestions.
4. **Experimentation and learning fourth:** measure whether recommendations are adopted and whether outcomes improve. Use controlled tests where practical.

AI must not invent missing analytics or pretend to know why a customer behaved a certain way. If there is insufficient data, say so and offer general educational guidance clearly labelled as such.

Design for usage limits, cost controls, caching, privacy, security and human review. Do not run expensive continuous AI analysis by default.

## 8. Unified Discovery

Explore a future **Purple Universal Search** that can discover relevant products, local services and professional talent across all three divisions.

For example, a search for “bedroom makeover” could surface:
- Furniture and home products from Purple Shop.
- Painters, carpenters or installers from Purple Handy Pro.
- Interior designers from Purple Professionals.

Provide division filters and relevant filters such as location, price, availability, category and verified status. Search results must remain relevant and clearly identify which division each result belongs to.

This is a future integration concept, not authorisation to replace existing search.

## 9. Product and Engineering Principles

- Extend the existing codebase; do not rebuild it.
- Preserve existing functionality, data, URLs, permissions, security controls and user workflows.
- Reuse existing components and services when appropriate.
- Avoid duplicate tables, overlapping features and unnecessary dependencies.
- Keep product, service and professional catalogues distinct where their business rules differ.
- Reuse shared identity, messaging, trust, reviews, promotions and analytics where technically sound.
- Keep business owners in control of published content, pricing, offers and AI-generated suggestions.
- Design for mobile-first use and practical conditions for small businesses.
- Document assumptions, dependencies, risks, data requirements and operating costs.

## 10. Phased Roadmap

This is a direction for future planning, not permission to start implementation immediately.

### Phase 0 — Current foundation
Continue the already approved Phase 1b foundation work. Preserve its scope, approval gates and production safeguards.

### Phase 1 — Product and architecture mapping
Map the three divisions to existing routes, components, roles, tables, storage, workflows and dashboards. Identify what already exists, what is partial, what needs improvement and what is genuinely new.

### Phase 2 — Core business journeys
After separate approval, prioritise complete, reliable journeys for product selling, service booking and professional project enquiries.

### Phase 3 — Measurement and insights
Implement reliable event tracking and useful analytics before advanced AI recommendations.

### Phase 4 — Marketing intelligence
Introduce rules-based tips, category-specific coaching, listing/profile improvement and customer-retention suggestions.

### Phase 5 — Advanced intelligence and discovery
Consider AI-assisted campaigns, experimentation, cross-division recommendations and universal search after data quality and costs are understood.

## 11. Required Repository Documentation

After inspecting the repository, create or update suitable documentation. Avoid creating duplicate documents if equivalent documents already exist.

Suggested documents:
- `docs/PURPLE-ECOSYSTEM-DIRECTION.md` — this product direction and its principles.
- `docs/PURPLE-DIVISIONS-AND-CATEGORIES.md` — the three divisions, category taxonomy and onboarding implications.
- `docs/PURPLE-MARKETING-INTELLIGENCE.md` — analytics, coaching, marketing strategies, guardrails and AI approach.
- `docs/PURPLE-FEATURE-INTEGRATION-MAP.md` — mapping to current implementation.
- `docs/PURPLE-ROADMAP.md` — phased, dependency-aware roadmap.
- Update `PROJECT_STATUS.md` with the document locations, decisions, open questions and explicit statement that no feature implementation was authorised by this planning task.

## 12. Required Inspection and Deliverables

Before proposing code changes:
1. Inspect the current repository and existing project documents.
2. Inspect relevant app routes, components, roles, database schema, migrations, RLS policies, storage, analytics and current seller/professional workflows.
3. Map existing functionality to the three divisions and Purple Marketing Intelligence.
4. Identify duplication, missing foundations, technical constraints, security implications and cost risks.
5. Recommend a minimal integration approach that preserves the current architecture.
6. Produce a prioritised roadmap with dependencies and acceptance criteria.
7. List unresolved product decisions for owner review.

Clearly classify each capability as:
- Already implemented.
- Partially implemented.
- Needs improvement.
- New — proposed.
- Future / deferred.

Do not claim a feature exists unless repository evidence supports that conclusion.

## 13. Strict Change-Control Rules

**This document redirects product strategy; it does not authorise implementation.**

During this task:
- Do not modify application code.
- Do not modify database schema, migrations, RLS policies, storage buckets or production settings.
- Do not change authentication, registration, navigation or existing user journeys.
- Do not add dependencies.
- Do not implement AI, analytics events, payments, campaigns or new features.
- Do not deploy anything or alter production or staging data.
- Do not rename, move or delete existing files unless separately approved.

Documentation changes are allowed only after repository inspection and should be limited to the project-direction and planning documents described above. Preserve existing documentation and record any proposed changes.

The existing Phase 1b foundation remains the immediate priority. Do not allow this broader product vision to delay, expand or interfere with its approved scope.

**Stop after inspection, mapping and documentation. Present findings and recommendations for review. Wait for explicit owner approval before any implementation.**
