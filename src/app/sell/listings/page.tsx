import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card, Notice, buttonClass } from "@/components/ui";
import { LISTING_CARD_SELECT, LISTING_STATUS, toListingCard } from "@/lib/catalog";
import { formatNaira } from "@/lib/money";
import { requireSeller } from "@/lib/seller";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Your listings · Purple Shop" };

export default function ListingsPage({ searchParams }: PageProps<"/sell/listings">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your listings…</p>}>
        <MyListings searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

async function MyListings({ searchParams }: { searchParams: PageProps<"/sell/listings">["searchParams"] }) {
  const user = await requireSeller("/sell/listings");
  const { saved } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase
    .from("listings")
    .select(`${LISTING_CARD_SELECT}, rejection_reason`)
    .eq("seller_id", user.id)
    .order("created_at", { ascending: false });
  const { data: saveRows } = await supabase.rpc("my_listing_save_counts");
  const saveCounts = new Map(((saveRows ?? []) as { listing_id: string; saves: number }[]).map((r) => [r.listing_id, Number(r.saves)]));
  const listings = (data ?? []).map((l) => ({ ...toListingCard(l), rejection: l.rejection_reason as string | null }));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <Link href="/sell" className="text-sm text-muted hover:text-brand">← Seller hub</Link>
          <h1 className="text-2xl font-bold text-brand-strong">Your listings</h1>
        </div>
        <Link href="/sell/listings/new" className={`${buttonClass} sm:w-auto`}>+ New listing</Link>
      </div>
      {saved && <Notice tone="success">Saved. Listings under review go live once the team approves them.</Notice>}
      {listings.length === 0 ? (
        <Card>
          <p className="text-sm text-muted">
            No listings yet. Add your first product or service. You can then tag it in your Purple Stories videos.
          </p>
        </Card>
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2">
          {listings.map((l) => {
            const status = LISTING_STATUS[l.status] ?? LISTING_STATUS.draft;
            const img = publicFileUrl("listing-images", l.image);
            return (
              <li key={l.id} className="flex gap-3 rounded-2xl border border-border bg-card p-3">
                {img ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={img} alt="" className="h-20 w-20 shrink-0 rounded-xl object-cover" />
                ) : (
                  <div className="h-20 w-20 shrink-0 rounded-xl bg-brand-soft" />
                )}
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium text-brand-strong">{l.title}</p>
                  <p className="text-sm">
                    {formatNaira(l.price_kobo)}
                    {(saveCounts.get(l.id) ?? 0) > 0 && (
                      <span className="ml-2 text-xs text-muted" title="People who saved this (we never show who)">
                        ♥ {saveCounts.get(l.id)} saved
                      </span>
                    )}
                  </p>
                  <div className="mt-1 flex flex-wrap items-center gap-2">
                    <span className={`rounded-full px-2 py-0.5 text-xs ${status.tone}`}>{status.text}</span>
                    <Link href={`/sell/listings/${l.id}`} className="text-xs font-medium text-brand hover:underline">Edit</Link>
                    {l.status === "approved" && (
                      <Link href={`/l/${l.id}`} className="text-xs text-muted hover:underline">View</Link>
                    )}
                  </div>
                  {l.status === "rejected" && l.rejection && (
                    <p className="mt-1 text-xs text-red-700">{l.rejection}</p>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
