import { cacheLife } from "next/cache";
import { createPublicClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";
import Link from "next/link";
import { Suspense } from "react";
import { ListingGrid } from "@/components/listing-grid";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/lib/auth";
import { readFilters, searchListings } from "@/lib/search";
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

      <section className="mt-10 rounded-3xl bg-brand px-6 py-10 text-white sm:px-10">
        <p className="text-sm font-medium uppercase tracking-widest text-accent">
          Discover. Create. Promote. Sell.
        </p>
        <h1 className="mt-3 text-3xl font-bold leading-tight sm:text-4xl">
          Turn your skills into a business people can find
        </h1>
        <p className="mt-3 max-w-xl text-white/85">
          Shop from Nigerian creatives, hire freelancers, and book verified pros for
          home repairs. Your money is held safely until the job is done.
        </p>
        <Suspense fallback={<HeroButtons signedIn={false} isSeller={false} />}>
          <HeroButtonsForUser />
        </Suspense>
        <p className="mt-4 text-xs text-white/70">No account needed to look around.</p>
      </section>

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
            <h2 className="text-xl font-semibold text-brand-strong">{s.name}</h2>
            <p className="mt-1 text-sm text-muted">{s.tagline}</p>

            <ul className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {s.categories.map((c) => (
                <li key={c.id}>
                  <Link
                    href={`/c/${c.slug}`}
                    className="block h-full rounded-2xl border border-border bg-card p-5 transition hover:border-brand"
                  >
                    <p className="font-semibold text-brand-strong">{c.name}</p>
                    <p className="mt-1 text-sm text-muted">{blurbs[c.slug] ?? ""}</p>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))
      )}

      <p className="mt-14 text-center text-sm text-muted">
        One account · verified reviews · safe escrow checkout · built-in promotion
      </p>
    </main>
  );
}

async function HeroButtonsForUser() {
  const user = await getCurrentUser();
  return <HeroButtons signedIn={!!user} isSeller={!!user && user.role !== "buyer"} />;
}

function HeroButtons({ signedIn, isSeller }: { signedIn: boolean; isSeller: boolean }) {
  return (
    <div className="mt-6 flex flex-wrap gap-3">
      <Link href="/search" className="rounded-full bg-white px-5 py-2.5 font-semibold text-brand hover:bg-brand-soft">
        Start shopping
      </Link>
      <Link
        href={isSeller ? "/sell" : signedIn ? "/welcome" : "/signup?intent=sell"}
        className="rounded-full border border-white/40 px-5 py-2.5 font-semibold text-white hover:bg-white/10"
      >
        {isSeller ? "Go to my shop" : "Sell on Purple Vendra"}
      </Link>
    </div>
  );
}

/** Latest stories and products, visible to everyone (no sign-up needed). */
async function HomeFeed() {
  const [viewer, stories, { listings }] = await Promise.all([
    getCurrentUser(),
    getFeedStories(null),
    searchListings(readFilters({ sort: "newest" }, null)),
  ]);

  return (
    <>
      {stories.length > 0 && (
        <section className="mt-12">
          <div className="mb-4 flex items-end justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-widest text-accent">Vendra Stories</p>
              <h2 className="text-xl font-semibold text-brand-strong">Watch makers at work, then shop what you see</h2>
            </div>
            <Link href="/stories" className="shrink-0 text-sm font-medium text-brand hover:underline">See all →</Link>
          </div>
          <StoryGallery stories={stories.slice(0, 8)} viewerId={viewer?.id ?? null} showSeller />
        </section>
      )}
      {listings.length > 0 && (
        <section className="mt-12">
          <div className="mb-4 flex items-end justify-between">
            <h2 className="text-xl font-semibold text-brand-strong">New on Purple Vendra</h2>
            <Link href="/search?sort=newest" className="shrink-0 text-sm font-medium text-brand hover:underline">Browse all →</Link>
          </div>
          <ListingGrid listings={listings.slice(0, 8)} />
        </section>
      )}
    </>
  );
}
