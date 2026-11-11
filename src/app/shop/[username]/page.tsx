import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { ReportButton } from "@/components/report-button";
import { FollowButton } from "@/components/shop-buttons";
import { SiteHeader } from "@/components/site-header";
import { StoryGallery } from "@/components/stories/story-gallery";
import { getCurrentUser } from "@/lib/auth";
import { ListingGrid } from "@/components/listing-grid";
import { LISTING_CARD_SELECT, toListingCard } from "@/lib/catalog";
import { DAYS } from "@/lib/nigeria";
import { getShopStories } from "@/lib/stories";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Shop · Purple Vendra" };

export default function ShopPage({ params, searchParams }: PageProps<"/shop/[username]">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading shop…</p>}>
        <Shop params={params} searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Shop({
  params,
  searchParams,
}: {
  params: PageProps<"/shop/[username]">["params"];
  searchParams: PageProps<"/shop/[username]">["searchParams"];
}) {
  const { username } = await params;
  const { story } = await searchParams;
  const supabase = await createClient();

  // RLS: only active seller profiles are public.
  const { data: seller } = await supabase
    .from("profiles")
    .select("id, username, display_name, business_name, headline, bio, city, state, is_verified, rating_avg, rating_count, avatar_url, years_experience, is_available, created_at")
    .eq("username", decodeURIComponent(username).toLowerCase())
    .eq("role", "seller")
    .maybeSingle();
  if (!seller) notFound();

  const name = seller.business_name || seller.display_name;
  const [viewer, stories, { data: listingRows }, { data: follow }, { data: hours }, { data: areas }] = await Promise.all([
    getCurrentUser(),
    getShopStories({ id: seller.id, username: seller.username, name, verified: seller.is_verified }),
    supabase
      .from("listings")
      .select(LISTING_CARD_SELECT)
      .eq("seller_id", seller.id)
      .eq("status", "approved")
      .order("created_at", { ascending: false }),
    supabase.rpc("seller_follow_info", { p_seller: seller.id }).single(),
    supabase.from("working_hours").select("day_of_week, opens_at, closes_at").eq("seller_id", seller.id).order("day_of_week"),
    supabase.from("service_areas").select("state, city").eq("seller_id", seller.id).order("state"),
  ]);
  const listings = (listingRows ?? []).map(toListingCard);
  const followInfo = (follow ?? { followers: 0, following: false }) as { followers: number; following: boolean };
  const isSelf = viewer?.id === seller.id;

  return (
    <div className="mt-8 space-y-10">
      {/* Shop header */}
      <section className="rounded-3xl bg-brand px-6 py-8 text-white sm:px-10">
        <div className="flex flex-wrap items-center gap-4">
          {seller.avatar_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={seller.avatar_url} alt="" className="h-16 w-16 rounded-full object-cover ring-2 ring-white/40" />
          ) : (
            <span className="flex h-16 w-16 items-center justify-center rounded-full bg-white/15 text-2xl font-bold">
              {name.slice(0, 1).toUpperCase()}
            </span>
          )}
          <div className="min-w-0 flex-1">
            <h1 className="text-2xl font-bold sm:text-3xl">
              {name} {seller.is_verified && <span title="ID verified" className="text-accent">✓</span>}
            </h1>
            <p className="text-sm text-white/80">
              @{seller.username}
              {(seller.city || seller.state) && ` · ${[seller.city, seller.state].filter(Boolean).join(", ")}`}
              {seller.rating_count > 0 && ` · ★ ${Number(seller.rating_avg).toFixed(1)} (${seller.rating_count})`}
            </p>
            {seller.headline && <p className="mt-1 text-white/90">{seller.headline}</p>}
          </div>
          <FollowButton sellerId={seller.id} initialFollowing={followInfo.following}
            initialCount={Number(followInfo.followers)} isSelf={isSelf} />
        </div>
        {seller.bio && <p className="mt-4 max-w-2xl whitespace-pre-line text-sm text-white/85">{seller.bio}</p>}
        <div className="mt-4 flex flex-wrap gap-2 text-xs">
          <span className={`rounded-full px-3 py-1 font-medium ${seller.is_available ? "bg-green-500/20 text-green-50" : "bg-white/15 text-white/80"}`}>
            {seller.is_available ? "● Taking orders" : "Not taking orders right now"}
          </span>
          {seller.years_experience != null && seller.years_experience > 0 && (
            <span className="rounded-full bg-white/15 px-3 py-1">{seller.years_experience} years experience</span>
          )}
          {seller.is_verified && <span className="rounded-full bg-white/15 px-3 py-1">ID verified</span>}
          <span className="rounded-full bg-white/15 px-3 py-1">
            On Purple Vendra since {new Date(seller.created_at).toLocaleDateString("en-NG", { month: "short", year: "numeric" })}
          </span>
        </div>
        {isSelf && (
          <div className="mt-4 flex flex-wrap gap-2 text-sm">
            <Link href="/sell/stories/new" className="rounded-full bg-white px-4 py-1.5 font-medium text-brand">+ Post a story</Link>
            <Link href="/sell/listings/new" className="rounded-full bg-white/15 px-4 py-1.5 font-medium">+ New listing</Link>
            <Link href="/sell/profile" className="rounded-full bg-white/15 px-4 py-1.5 font-medium">Edit profile</Link>
          </div>
        )}
      </section>

      {/* Vendra Stories */}
      <section id="stories">
        <div className="mb-4 flex items-end justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-widest text-accent">Vendra Stories</p>
            <h2 className="text-xl font-semibold text-brand-strong">Watch {name} at work</h2>
          </div>
          {stories.length > 0 && <span className="text-sm text-muted">{stories.length} videos</span>}
        </div>
        {stories.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-border p-6 text-center text-sm text-muted">
            {isSelf ? "Post your first story to show buyers how you work." : "No stories yet."}
          </p>
        ) : (
          <StoryGallery stories={stories} viewerId={viewer?.id ?? null}
            initialStoryId={typeof story === "string" ? story : undefined} />
        )}
      </section>

      {/* Listings */}
      <section id="products">
        <h2 className="mb-4 text-xl font-semibold text-brand-strong">Products & services</h2>
        {listings.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-border p-6 text-center text-sm text-muted">Nothing listed yet.</p>
        ) : (
          <ListingGrid listings={listings.map((l) => ({ ...l, image_path: l.image }))} />
        )}
      </section>

      {((hours ?? []).length > 0 || (areas ?? []).length > 0) && (
        <section className="grid gap-4 sm:grid-cols-2">
          {(hours ?? []).length > 0 && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <h2 className="font-semibold text-brand-strong">Working hours</h2>
              <ul className="mt-2 space-y-1 text-sm">
                {DAYS.map((d, i) => {
                  const h = (hours ?? []).find((x) => x.day_of_week === i);
                  return (
                    <li key={d} className="flex justify-between">
                      <span className="text-muted">{d}</span>
                      <span className="tabular-nums">{h ? `${String(h.opens_at).slice(0, 5)} – ${String(h.closes_at).slice(0, 5)}` : "Closed"}</span>
                    </li>
                  );
                })}
              </ul>
            </div>
          )}
          {(areas ?? []).length > 0 && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <h2 className="font-semibold text-brand-strong">Delivers to / works in</h2>
              <ul className="mt-2 flex flex-wrap gap-2 text-sm">
                {(areas ?? []).map((a) => (
                  <li key={`${a.state}-${a.city}`} className="rounded-full bg-brand-soft px-3 py-1 text-brand">
                    {a.city === "All areas" ? `All of ${a.state}` : `${a.city}, ${a.state}`}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </section>
      )}

      {!isSelf && (
        <div className="max-w-md">
          <ReportButton userId={seller.id} />
        </div>
      )}
    </div>
  );
}
