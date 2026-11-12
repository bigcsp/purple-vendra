import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { SiteHeader } from "@/components/site-header";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/lib/auth";
import { getCategories } from "@/lib/catalog";
import { getFeedStories, getStoryById } from "@/lib/stories";

export const metadata: Metadata = { title: "Purple Stories · Purple Shop" };

export default function StoriesPage({ searchParams }: PageProps<"/stories">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <section className="mt-8">
        <p className="text-xs font-semibold text-accent">Purple Stories</p>
        <h1 className="text-3xl font-bold text-brand-strong">See it made. Shop it right here.</h1>
        <p className="mt-1 max-w-xl text-muted">Short videos from Nigerian makers and pros. Tap a video, then tap a product to buy.</p>
      </section>
      <Suspense fallback={<p className="mt-8 text-sm text-muted">Loading stories…</p>}>
        <Feed searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Feed({ searchParams }: { searchParams: PageProps<"/stories">["searchParams"] }) {
  const { category, story } = await searchParams;
  const storyId = typeof story === "string" ? story : undefined;
  const [categories, viewer] = await Promise.all([getCategories(), getCurrentUser()]);
  const active = categories.find((c) => c.slug === category) ?? null;
  let stories = await getFeedStories(active?.id ?? null);
  // A story linked from search that isn't in this feed: put it first.
  if (storyId && !stories.some((s) => s.id === storyId)) {
    const linked = await getStoryById(storyId);
    if (linked) stories = [linked, ...stories];
  }

  return (
    <div className="mt-6 space-y-6">
      <nav className="-mx-5 flex gap-2 overflow-x-auto px-5 pb-1">
        <Chip href="/stories" active={!active}>All</Chip>
        {categories.map((c) => (
          <Chip key={c.id} href={`/stories?category=${c.slug}`} active={active?.id === c.id}>{c.name}</Chip>
        ))}
      </nav>
      {stories.length === 0 ? (
        <p className="rounded-2xl border border-dashed border-border p-8 text-center text-sm text-muted">
          No stories here yet. Sellers: post yours from the Seller hub.
        </p>
      ) : (
        <StoryGallery stories={stories} viewerId={viewer?.id ?? null} showSeller initialStoryId={storyId} />
      )}
    </div>
  );
}

function Chip({ href, active, children }: { href: string; active: boolean; children: React.ReactNode }) {
  return (
    <Link href={href}
      className={`shrink-0 rounded-full px-4 py-1.5 text-sm font-medium ${
        active ? "bg-brand text-white" : "border border-border bg-card text-brand hover:bg-brand-soft"
      }`}>
      {children}
    </Link>
  );
}
