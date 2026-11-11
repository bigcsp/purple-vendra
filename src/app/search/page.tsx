import type { Metadata } from "next";
import { Suspense } from "react";
import { SearchResults } from "@/components/search-results";
import { SiteHeader } from "@/components/site-header";
import { getCategories } from "@/lib/catalog";
import { readFilters } from "@/lib/search";

export const metadata: Metadata = { title: "Search · Purple Vendra" };

export default function SearchPage({ searchParams }: PageProps<"/search">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Searching…</p>}>
        <Search searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Search({ searchParams }: { searchParams: PageProps<"/search">["searchParams"] }) {
  const params = await searchParams;
  const categories = await getCategories();
  const slug = Array.isArray(params.category) ? params.category[0] : params.category;
  const category = categories.find((c) => c.slug === slug) ?? null;
  const filters = readFilters(params, category?.id ?? null);

  return (
    <div className="mt-8 space-y-4">
      <h1 className="text-2xl font-bold text-brand-strong">
        {filters.q ? <>Results for “{filters.q}”</> : category ? category.name : "Browse everything"}
      </h1>
      <SearchResults filters={filters} basePath="/search" categories={categories} />
    </div>
  );
}
