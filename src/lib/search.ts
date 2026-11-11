import "server-only";

import type { GridListing } from "@/components/listing-grid";
import { nairaToKobo } from "@/lib/money";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { createClient } from "@/lib/supabase/server";

export const SORTS = {
  relevance: "Best match",
  newest: "Newest",
  price_low: "Price: low to high",
  price_high: "Price: high to low",
  rating: "Top rated",
} as const;
export type Sort = keyof typeof SORTS;

export const PAGE_SIZE = 24;

export type SearchFilters = {
  q: string;
  categoryId: number | null;
  state: string | null;
  type: "product" | "service" | "talent" | null;
  min: string;
  max: string;
  sort: Sort;
  page: number;
};

type Raw = Record<string, string | string[] | undefined>;
const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";

/** Reads and cleans search filters from the URL. */
export function readFilters(params: Raw, categoryId: number | null): SearchFilters {
  const state = one(params.state);
  const type = one(params.type);
  const sort = one(params.sort) as Sort;
  const q = one(params.q).trim().slice(0, 200);
  return {
    q,
    categoryId,
    state: (NIGERIAN_STATES as readonly string[]).includes(state) ? state : null,
    type: type === "product" || type === "service" || type === "talent" ? type : null,
    min: one(params.min).trim(),
    max: one(params.max).trim(),
    sort: sort in SORTS ? sort : q ? "relevance" : "newest",
    page: Math.max(1, Math.min(50, Number.parseInt(one(params.page) || "1", 10) || 1)),
  };
}

export async function searchListings(f: SearchFilters): Promise<{ listings: GridListing[]; total: number }> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("search_listings", {
    p_query: f.q || null,
    p_category: f.categoryId,
    p_state: f.state,
    p_type: f.type,
    p_min_kobo: f.min ? nairaToKobo(f.min) : null,
    p_max_kobo: f.max ? nairaToKobo(f.max) : null,
    p_sort: f.sort,
    p_limit: PAGE_SIZE,
    p_offset: (f.page - 1) * PAGE_SIZE,
  });
  if (error) throw new Error(error.message);
  type Row = {
    id: string; title: string; price_kobo: number; price_is_starting: boolean; quote_on_request: boolean;
    image_path: string | null; seller_username: string; seller_name: string; seller_verified: boolean;
    city: string | null; state: string | null; featured: boolean; total_count: number;
  };
  const rows = (data ?? []) as Row[];
  return {
    total: Number(rows[0]?.total_count ?? 0),
    listings: rows.map((r) => ({
      id: r.id,
      title: r.title,
      price_kobo: r.price_kobo,
      price_is_starting: r.price_is_starting,
      quote_on_request: r.quote_on_request,
      image_path: r.image_path,
      featured: r.featured,
      seller: { username: r.seller_username, name: r.seller_name, verified: r.seller_verified },
      place: r.city || r.state,
    })),
  };
}

export type SellerHit = {
  id: string; username: string; name: string; headline: string | null; avatar_url: string | null;
  city: string | null; state: string | null; is_verified: boolean; rating_avg: number | null;
  rating_count: number; listings: number;
};

export async function searchSellers(q: string): Promise<SellerHit[]> {
  if (!q) return [];
  const supabase = await createClient();
  const { data } = await supabase.rpc("search_sellers", { p_query: q, p_limit: 6 });
  return (data ?? []) as SellerHit[];
}

/** Anonymous demand log (what people look for). Never blocks the page. */
export async function logSearch(q: string, categoryId: number | null, results: number) {
  if (!q) return;
  try {
    const supabase = await createClient();
    await supabase.rpc("log_search", { p_query: q, p_category: categoryId, p_results: results });
  } catch {
    /* logging must never break search */
  }
}
