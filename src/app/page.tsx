import { cacheLife } from "next/cache";
import { createPublicClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";
import Link from "next/link";
import { Suspense } from "react";
import { AdireField } from "@/components/adire";
import { ListingGrid } from "@/components/listing-grid";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/lib/auth";
import { readFilters, searchListings } from "@/lib/search";
import { SearchBox } from "@/components/search-box";
import { RecentlyViewed } from "@/components/recently-viewed";
import { getFeedStories } from "@/lib/stories";
import { SiteHeader } from "@/components/site-header";

type Category = { id: number; slug: string; name: string };
type Section = {
  id: number;
  slug: string;
  name: string;
  tagline: string;
  categories: Category[];
};

const icons: Record<string, string> = {
  "fashion-adire": "👗",
  "art-crafts": "🎨",
  "digital-design": "🖌️",
  "photo-video-talent": "📸",
  "tech-freelance": "💻",
  "home-services": "🔧",
};

const blurbs: Record<string, string> = {
  "fashion-adire": "Tailors, Ankara and Adire, accessories",
  "art-crafts": "Paintings, prints, handmade pieces",
  "digital-design": "Logos, flyers, templates, editing",
  "photo-video-talent": "Photographers, videographers, models, MUAs",
  "tech-freelance": "Web & app devs, social media, writers, VAs",
  "home-services": "Plumbers, electricians, AC & generator repair, cleaners",
};

async function getSections(): Promise<{ data: Section[]; error?: string }> {
  "use cache";
  cacheLife("minutes");

  if (!isSupabaseConfigured) {
    return { data: [], error: "Supabase keys are missing. Add them to .env.local." };
  }

  const { data, error } = await createPublicClient()
    .from("sections")
    .select("id, slug, name, tagline, categories(id, slug, name)")
    .order("position")
    .order("position", { referencedTable: "categories" });

  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as Section[] };
}

export default async function Home() {
  const { data: sections, error } = await getSections();

  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />

      <section className="relative z-10 mt-6 rounded-[2rem] bg-panel text-white">
        {/* Pattern is clipped in its own layer so the search suggestions can spill below the hero. */}
        <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-[2rem]" aria-hidden>
          <AdireField className="absolute inset-y-0 right-0 hidden h-full w-[42%] [mask-image:linear-gradient(to_right,transparent,black_45%)] md:block" />
          <AdireField className="absolute -bottom-24 -right-24 h-72 w-72 opacity-40 md:hidden" />
        </div>
        <div className="relative px-6 py-10 sm:px-10 sm:py-14 md:max-w-[60%]">
          <h1 className="font-display text-4xl font-extrabold leading-[1.05] sm:text-5xl">
            Find Nigerian makers, freelancers and pros you can trust.
          </h1>
          <p className="mt-4 max-w-lg text-base text-white/85">
            Shop adire and art, hire designers and developers, book a plumber. You pay through Purple Shop and we
            hold your money until you get what you paid for.
          </p>
          <div className="mt-6 max-w-lg">
            <SearchBox variant="hero" placeholder="Search anything…" />
          </div>
          <div className="mt-4 flex flex-wrap gap-2 text-sm">
            {["Adire", "Aso-ebi", "Logo design", "Makeup artist", "Plumber", "Website"].map((q) => (
              <Link key={q} href={`/search?q=${encodeURIComponent(q)}`}
                className="rounded-full border border-white/25 px-3 py-1 text-white/90 transition hover:border-[#e8a317] hover:text-white">
                {q}
              </Link>
            ))}
          </div>
          <Suspense fallback={<HeroButtons signedIn={false} isSeller={false} />}>
            <HeroButtonsForUser />
          </Suspense>
        </div>
      </section>

      <div className="mt-12 empty:hidden">
        <RecentlyViewed title="Pick up where you left off" />
      </div>

      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading what&apos;s new…</p>}>
        <HomeFeed />
      </Suspense>

      {error ? (
        <p className="mt-10 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          Couldn&apos;t load the marketplaces: {error}
        </p>
      ) : (
        sections.map((s) => (
          <section key={s.id} className="mt-12" id={s.slug}>
            <h2 className="text-2xl font-bold text-brand-strong">{s.name}</h2>
            <p className="mt-1 text-sm text-muted">{s.tagline}</p>

            <ul className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {s.categories.map((c) => (
                <li key={c.id}>
                  <Link
                    href={`/c/${c.slug}`}
                    className="group flex h-full items-start gap-4 rounded-2xl border border-border bg-card p-5 transition hover:border-brand"
                  >
                    <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-brand-soft text-2xl transition group-hover:scale-105" aria-hidden>
                      {icons[c.slug] ?? "✨"}
                    </span>
                    <span>
                      <span className="block font-semibold text-brand-strong">{c.name}</span>
                      <span className="mt-0.5 block text-sm text-muted">{blurbs[c.slug] ?? ""}</span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))
      )}

      <section className="mt-16 grid gap-4 rounded-[2rem] border border-border bg-card p-6 sm:grid-cols-3 sm:p-8">
        {[
          { icon: "🔒", title: "Your money is protected", text: "We hold payment until you confirm you received your order or the job is done." },
          { icon: "✅", title: "Verified sellers", text: "Every seller signs in with two-step security, and verified sellers have checked ID." },
          { icon: "⭐", title: "Honest reviews", text: "Only people who actually bought or booked can leave a review." },
        ].map((f) => (
          <div key={f.title}>
            <span className="text-2xl" aria-hidden>{f.icon}</span>
            <h3 className="mt-2 font-semibold text-brand-strong">{f.title}</h3>
            <p className="mt-1 text-sm text-muted">{f.text}</p>
          </div>
        ))}
      </section>
    </main>
  );
}

async function HeroButtonsForUser() {
  const user = await getCurrentUser();
  return <HeroButtons signedIn={!!user} isSeller={!!user && user.role !== "buyer"} />;
}

function HeroButtons({ signedIn, isSeller }: { signedIn: boolean; isSeller: boolean }) {
  return (
    <div className="mt-7 flex flex-wrap items-center gap-4 text-sm">
      <Link
        href={isSeller ? "/sell" : signedIn ? "/welcome" : "/signup?intent=sell"}
        className="rounded-full bg-[#e8a317] px-5 py-2.5 font-semibold text-[#241045] hover:brightness-105"
      >
        {isSeller ? "Go to my shop" : "Sell on Purple Shop"}
      </Link>
      <span className="text-white/70">{isSeller ? "Your shop, stories and orders" : "Free to join. No account needed to look around."}</span>
    </div>
  );
}

/** Latest stories and products, visible to everyone (no sign-up needed). */
async function HomeFeed() {
  // A hiccup loading the feed shouldn't break the homepage.
  const [viewer, stories, { listings }] = await Promise.all([
    getCurrentUser().catch(() => null),
    getFeedStories(null).catch(() => []),
    searchListings(readFilters({ sort: "newest" }, null)).catch(() => ({ listings: [], total: 0 })),
  ]);

  return (
    <>
      {stories.length > 0 && (
        <section className="mt-12">
          <div className="mb-4 flex items-end justify-between">
            <div>
              <h2 className="text-2xl font-bold text-brand-strong">Purple Stories</h2>
              <p className="mt-0.5 text-sm text-muted">Watch makers at work, then shop what you see.</p>
            </div>
            <Link href="/stories" className="shrink-0 text-sm font-medium text-brand hover:underline">See all →</Link>
          </div>
          <StoryGallery stories={stories.slice(0, 8)} viewerId={viewer?.id ?? null} showSeller />
        </section>
      )}
      {listings.length > 0 && (
        <section className="mt-12">
          <div className="mb-4 flex items-end justify-between">
            <h2 className="text-2xl font-bold text-brand-strong">New on Purple Shop</h2>
            <Link href="/search?sort=newest" className="shrink-0 text-sm font-medium text-brand hover:underline">Browse all →</Link>
          </div>
          <ListingGrid listings={listings.slice(0, 8)} />
        </section>
      )}
    </>
  );
}
