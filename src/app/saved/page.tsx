import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { ListingGrid } from "@/components/listing-grid";
import { PageShell } from "@/components/page-shell";
import { RecentlyViewed } from "@/components/recently-viewed";
import { getCurrentUser } from "@/server/auth/session";
import { LISTING_CARD_SELECT, toListingCard } from "@/server/queries/catalog";
import { createClient } from "@/server/db/supabase";

export const metadata: Metadata = { title: "Saved · Purple Shop" };

export default function SavedPage() {
  return (
    <PageShell>
      <div className="space-y-10">
        <Suspense fallback={<p className="text-sm text-muted">Loading your saved items…</p>}>
          <Saved />
        </Suspense>
        <RecentlyViewed />
      </div>
    </PageShell>
  );
}

type SavedRow = { created_at: string; listings: Parameters<typeof toListingCard>[0] | null };
type FollowRow = {
  created_at: string;
  profiles: { username: string; display_name: string; business_name: string | null; avatar_url: string | null; is_verified: boolean; headline: string | null } | null;
};

async function Saved() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <div className="rounded-3xl border border-border bg-card p-8 text-center">
        <h1 className="text-2xl font-bold text-brand-strong">Saved</h1>
        <p className="mt-2 text-muted">Tap the heart on anything you like to keep it here, on your phone and computer.</p>
        <Link href="/signup?reason=save&next=/saved" className="mt-4 inline-block rounded-full bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">
          Create a free account
        </Link>
        <p className="mt-3 text-sm text-muted">
          Have one? <Link href="/login?next=/saved" className="text-brand underline">Sign in</Link>
        </p>
      </div>
    );
  }

  const supabase = await createClient();
  const [{ data: saved }, { data: follows }] = await Promise.all([
    supabase
      .from("saves")
      .select(`created_at, listings(${LISTING_CARD_SELECT})`)
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(200),
    supabase
      .from("follows")
      .select("created_at, profiles!follows_seller_id_fkey(username, display_name, business_name, avatar_url, is_verified, headline)")
      .eq("follower_id", user.id)
      .order("created_at", { ascending: false })
      .limit(100),
  ]);

  const rows = ((saved ?? []) as unknown as SavedRow[]).filter((r) => r.listings);
  const live = rows.filter((r) => r.listings!.status === "approved").map((r) => toListingCard(r.listings!));
  const gone = rows.length - live.length;
  const shops = ((follows ?? []) as unknown as FollowRow[]).filter((f) => f.profiles);

  return (
    <div className="space-y-10">
      <section>
        <h1 className="text-2xl font-bold text-brand-strong">Saved</h1>
        <p className="mb-4 text-sm text-muted">
          {live.length === 0 ? "Nothing saved yet." : `${live.length} saved item${live.length === 1 ? "" : "s"}.`} Only you can see this list.
        </p>
        {live.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-border bg-card p-8 text-center text-sm text-muted">
            <p>Tap the heart on any product or service to save it for later.</p>
            <Link href="/search" className="mt-4 inline-block rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-deep">
              Start browsing
            </Link>
          </div>
        ) : (
          <ListingGrid listings={live.map((l) => ({ ...l, image_path: l.image }))} />
        )}
        {gone > 0 && (
          <p className="mt-3 text-xs text-muted">
            {gone} saved item{gone === 1 ? " is" : "s are"} no longer available and hidden from this list.
          </p>
        )}
      </section>

      <section>
        <h2 className="text-xl font-bold text-brand-strong">Shops you follow</h2>
        {shops.length === 0 ? (
          <p className="mt-2 text-sm text-muted">Follow a shop to see it here and keep up with their new work.</p>
        ) : (
          <ul className="mt-3 grid gap-3 sm:grid-cols-2">
            {shops.map((f) => {
              const p = f.profiles!;
              const name = p.business_name || p.display_name;
              return (
                <li key={p.username}>
                  <Link href={`/shop/${p.username}`} className="flex items-center gap-3 rounded-2xl border border-border bg-card p-3 hover:border-brand">
                    {p.avatar_url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={p.avatar_url} alt="" className="h-12 w-12 rounded-full object-cover" />
                    ) : (
                      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brand-soft font-bold text-brand">
                        {name.slice(0, 1).toUpperCase()}
                      </span>
                    )}
                    <span className="min-w-0">
                      <span className="block truncate font-medium">
                        {name} {p.is_verified && <span className="text-green-700">✓</span>}
                      </span>
                      <span className="block truncate text-xs text-muted">{p.headline || `@${p.username}`}</span>
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
