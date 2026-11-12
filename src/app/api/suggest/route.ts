import { NextResponse, type NextRequest } from "next/server";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/lib/supabase/server";

export type Suggestion = {
  kind: "search" | "category" | "shop" | "listing" | "story";
  label: string;
  detail: string | null;
  href: string;
  image: string | null;
  verified: boolean;
};

type Row = { kind: Suggestion["kind"]; label: string; detail: string | null; slug: string | null; image: string | null; verified: boolean };

/**
 * GET /api/suggest?q=aso        → instant suggestions while typing
 * GET /api/suggest?popular=1    → popular searches (for an empty search box)
 * Public data only; works signed in or out.
 */
export async function GET(request: NextRequest) {
  const q = (request.nextUrl.searchParams.get("q") ?? "").trim().slice(0, 60);
  const popular = request.nextUrl.searchParams.get("popular") === "1";
  const supabase = await createClient();

  if (popular) {
    const { data } = await supabase.rpc("popular_searches", { p_prefix: null, p_limit: 8 });
    const items = ((data ?? []) as { query: string }[]).map((r) => r.query);
    return NextResponse.json({ popular: items }, { headers: { "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600" } });
  }

  if (q.length < 2) return NextResponse.json({ items: [] });

  const { data, error } = await supabase.rpc("search_suggest", { p_query: q, p_limit: 12 });
  if (error) return NextResponse.json({ items: [] }, { status: 200 });

  const items: Suggestion[] = ((data ?? []) as Row[]).map((r) => ({
    kind: r.kind,
    label: r.label,
    detail: r.detail,
    verified: r.verified,
    href:
      r.kind === "category" ? `/c/${r.slug}`
      : r.kind === "shop" ? `/shop/${r.slug}`
      : r.kind === "listing" ? `/l/${r.slug}`
      : r.kind === "story" ? `/stories?story=${r.slug}`
      : `/search?q=${encodeURIComponent(r.label)}`,
    image:
      r.kind === "listing" ? publicFileUrl("listing-images", r.image)
      : r.kind === "story" ? publicFileUrl("story-media", r.image)
      : r.kind === "shop" ? r.image
      : null,
  }));

  return NextResponse.json({ items }, { headers: { "Cache-Control": "public, s-maxage=30, stale-while-revalidate=120" } });
}
