import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { SearchResults } from "@/components/search-results";
import { SiteHeader } from "@/components/site-header";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/lib/auth";
import { getCategories } from "@/lib/catalog";
import { readFilters } from "@/lib/search";
import { getFeedStories } from "@/lib/stories";

export const metadata: Metadata = { title: "Category · Purple Vendra" };

export default function CategoryPage({ params, searchParams }: PageProps<"/c/[slug]">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading…</p>}>
        <Category params={params} searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Category({
  params,
  searchParams,
}: {
  params: PageProps<"/c/[slug]">["params"];
  searchParams: PageProps<"/c/[slug]">["searchParams"];
}) {
  const [{ slug }, query, categories] = await Promise.all([params, searchParams, getCategories()]);
  const category = categories.find((c) => c.slug === slug);
  if (!category) notFound();
  const filters = readFilters(query, category.id);
  const [stories, viewer] = await Promise.all([
    filters.page === 1 && !filters.q ? getFeedStories(category.id) : Promise.resolve([]),
    getCurrentUser(),
  ]);
  const categoryStories = stories.slice(0, 8);

  return (
    <div className="mt-8 space-y-8">
      <div>
        <Link href="/" className="text-sm text-muted hover:text-brand">← All marketplaces</Link>
        <p className="mt-1 text-xs font-semibold text-accent">{category.section}</p>
        <h1 className="text-3xl font-bold text-brand-strong">{category.name}</h1>
      </div>

      {categoryStories.length > 0 && (
        <section>
          <div className="mb-3 flex items-end justify-between">
            <h2 className="text-lg font-semibold text-brand-strong">Vendra Stories</h2>
            <Link href={`/stories?category=${category.slug}`} className="text-sm text-brand hover:underline">See all →</Link>
          </div>
          <StoryGallery stories={categoryStories} viewerId={viewer?.id ?? null} showSeller />
        </section>
      )}

      <SearchResults filters={filters} basePath={`/c/${category.slug}`} categories={categories} lockedCategory={category} />
    </div>
  );
}
