import Link from "next/link";
import { ListingGrid } from "@/components/listing-grid";
import type { Category } from "@/server/queries/catalog";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/server/auth/session";
import { PAGE_SIZE, SORTS, didYouMean, logSearch, searchListings, searchSellers, type SearchFilters } from "@/server/queries/search";
import { searchStories } from "@/server/queries/stories";

const selectClass = "rounded-xl border border-border bg-card px-3 py-2 text-sm outline-none focus:border-brand";

/**
 * Filters + results for /search and /c/[slug]. Filters are a plain GET form,
 * so search works without JavaScript and every result page has a shareable link.
 */
export async function SearchResults({
  filters,
  basePath,
  categories,
  lockedCategory,
}: {
  filters: SearchFilters;
  basePath: string;
  categories: Category[];
  lockedCategory?: Category;
}) {
  const firstPage = filters.page === 1;
  const [{ listings, total }, sellers, stories, viewer] = await Promise.all([
    searchListings(filters),
    firstPage ? searchSellers(filters.q) : Promise.resolve([]),
    firstPage && filters.q ? searchStories(filters.q, 8).catch(() => []) : Promise.resolve([]),
    getCurrentUser(),
  ]);
  const nothing = total === 0 && sellers.length === 0 && stories.length === 0;
  const suggestion = nothing && filters.q ? await didYouMean(filters.q) : null;
  if (firstPage) await logSearch(filters.q, filters.categoryId, total + sellers.length + stories.length);

  const pages = Math.ceil(total / PAGE_SIZE);
  const linkTo = (page: number) => {
    const params = new URLSearchParams();
    if (filters.q) params.set("q", filters.q);
    if (!lockedCategory && filters.categoryId) {
      const c = categories.find((x) => x.id === filters.categoryId);
      if (c) params.set("category", c.slug);
    }
    if (filters.state) params.set("state", filters.state);
    if (filters.type) params.set("type", filters.type);
    if (filters.min) params.set("min", filters.min);
    if (filters.max) params.set("max", filters.max);
    params.set("sort", filters.sort);
    if (page > 1) params.set("page", String(page));
    return `${basePath}?${params}`;
  };
  const activeCategory = categories.find((c) => c.id === filters.categoryId);
  const anyFilter = filters.state || filters.type || filters.min || filters.max || (!lockedCategory && filters.categoryId);

  return (
    <div className="space-y-6">
      <form action={basePath} className="flex flex-wrap items-end gap-2 rounded-2xl border border-border bg-card p-3">
        {lockedCategory ? null : (
          <>
            <input type="hidden" name="q" value={filters.q} />
            <select name="category" defaultValue={activeCategory?.slug ?? ""} className={selectClass} aria-label="Category">
              <option value="">All categories</option>
              {categories.map((c) => <option key={c.id} value={c.slug}>{c.name}</option>)}
            </select>
          </>
        )}
        {lockedCategory && (
          <input name="q" defaultValue={filters.q} placeholder={`Search ${lockedCategory.name}`}
            className={`${selectClass} min-w-0 flex-1 basis-48`} aria-label="Search in this category" />
        )}
        <select name="state" defaultValue={filters.state ?? ""} className={selectClass} aria-label="State">
          <option value="">All of Nigeria</option>
          {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <select name="type" defaultValue={filters.type ?? ""} className={selectClass} aria-label="Type">
          <option value="">Products & services</option>
          <option value="product">Products</option>
          <option value="service">Services</option>
          <option value="talent">Talent</option>
        </select>
        <input name="min" defaultValue={filters.min} inputMode="numeric" placeholder="Min ₦" className={`${selectClass} w-24`} aria-label="Minimum price" />
        <input name="max" defaultValue={filters.max} inputMode="numeric" placeholder="Max ₦" className={`${selectClass} w-24`} aria-label="Maximum price" />
        <select name="sort" defaultValue={filters.sort} className={selectClass} aria-label="Sort">
          {Object.entries(SORTS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
        <button className="rounded-xl bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-deep">Apply</button>
        {anyFilter && (
          <Link href={filters.q && !lockedCategory ? `${basePath}?q=${encodeURIComponent(filters.q)}` : basePath}
            className="px-2 py-2 text-sm text-muted hover:text-brand">Clear filters</Link>
        )}
      </form>

      {suggestion && (
        <p className="rounded-2xl border border-brand/25 bg-brand-soft/60 px-4 py-3 text-sm">
          Did you mean{" "}
          <Link href={`${basePath}?q=${encodeURIComponent(suggestion)}`} className="font-semibold text-brand underline">
            {suggestion}
          </Link>
          ?
        </p>
      )}

      {filters.q && firstPage && (sellers.length > 0 || stories.length > 0) && (
        <nav aria-label="Jump to" className="flex flex-wrap gap-2 text-sm">
          <a href="#results-listings" className="rounded-full border border-border bg-card px-3 py-1 text-brand hover:bg-brand-soft">
            Products & services · {total}
          </a>
          {sellers.length > 0 && (
            <a href="#results-shops" className="rounded-full border border-border bg-card px-3 py-1 text-brand hover:bg-brand-soft">
              Shops · {sellers.length}
            </a>
          )}
          {stories.length > 0 && (
            <a href="#results-stories" className="rounded-full border border-border bg-card px-3 py-1 text-brand hover:bg-brand-soft">
              Stories · {stories.length}
            </a>
          )}
        </nav>
      )}

      {sellers.length > 0 && (
        <section id="results-shops" className="scroll-mt-24">
          <h2 className="mb-2 text-sm font-semibold text-muted">Shops</h2>
          <ul className="flex gap-3 overflow-x-auto pb-1">
            {sellers.map((s) => (
              <li key={s.id} className="shrink-0">
                <Link href={`/shop/${s.username}`} className="flex w-64 items-center gap-3 rounded-2xl border border-border bg-card p-3 hover:border-brand">
                  {s.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={s.avatar_url} alt="" className="h-12 w-12 rounded-full object-cover" />
                  ) : (
                    <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brand-soft font-bold text-brand">
                      {s.name.slice(0, 1).toUpperCase()}
                    </span>
                  )}
                  <span className="min-w-0">
                    <span className="block truncate font-medium">{s.name} {s.is_verified && <span className="text-green-700">✓</span>}</span>
                    <span className="block truncate text-xs text-muted">{s.headline || `@${s.username}`}</span>
                    <span className="block text-xs text-muted">
                      {s.listings} listing{Number(s.listings) === 1 ? "" : "s"}
                      {s.rating_count > 0 && ` · ★ ${Number(s.rating_avg).toFixed(1)}`}
                      {s.state && ` · ${s.state}`}
                    </span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}

      {stories.length > 0 && (
        <section id="results-stories" className="scroll-mt-24">
          <h2 className="mb-2 text-sm font-semibold text-muted">Purple Stories</h2>
          <StoryGallery stories={stories} viewerId={viewer?.id ?? null} showSeller />
        </section>
      )}

      <section id="results-listings" className="scroll-mt-24">
        {(sellers.length > 0 || stories.length > 0) && <h2 className="mb-1 text-sm font-semibold text-muted">Products & services</h2>}
        <p className="mb-3 text-sm text-muted">
          {total === 0
            ? "No results"
            : `${total.toLocaleString()} result${total === 1 ? "" : "s"}${pages > 1 ? ` · page ${filters.page} of ${pages}` : ""}`}
        </p>
        {total === 0 ? (
          <div className="rounded-2xl border border-dashed border-border p-8 text-center text-sm text-muted">
            <p>
              {sellers.length || stories.length
                ? `No products or services match${filters.q ? ` “${filters.q}”` : ""} yet, but see the shops and stories above.`
                : `Nothing matches${filters.q ? ` “${filters.q}”` : ""} yet.`}
            </p>
            <p className="mt-1">Try fewer words, another spelling, or remove a filter. New sellers join every week.</p>
            <Link
              href={`/requests/new${filters.q ? `?title=${encodeURIComponent(filters.q)}` : ""}`}
              className="mt-4 inline-block rounded-full bg-brand px-5 py-2.5 font-medium text-white hover:bg-brand-deep"
            >
              Post a request{filters.q ? ` for “${filters.q}”` : ""}
            </Link>
            <p className="mt-2 text-xs">Sellers send you offers. You choose, and pay safely through escrow.</p>
            <div className="mt-4 flex flex-wrap justify-center gap-2">
              {["Aso ebi", "Ankara", "Logo design", "Makeup artist", "Plumber", "Photographer"].map((x) => (
                <Link key={x} href={`/search?q=${encodeURIComponent(x)}`} className="rounded-full border border-border bg-card px-3 py-1 text-brand hover:bg-brand-soft">
                  {x}
                </Link>
              ))}
            </div>
          </div>
        ) : (
          <ListingGrid listings={listings} />
        )}
        {pages > 1 && (
          <nav className="mt-6 flex items-center justify-center gap-2 text-sm" aria-label="Pages">
            {filters.page > 1 && (
              <Link href={linkTo(filters.page - 1)} className="rounded-xl border border-border px-4 py-2 text-brand hover:bg-brand-soft">← Previous</Link>
            )}
            {filters.page < pages && (
              <Link href={linkTo(filters.page + 1)} className="rounded-xl border border-border px-4 py-2 text-brand hover:bg-brand-soft">Next →</Link>
            )}
          </nav>
        )}
      </section>
    </div>
  );
}
