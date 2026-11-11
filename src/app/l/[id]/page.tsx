import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { ReportButton } from "@/components/report-button";
import { AddToCartButton } from "@/components/shop-buttons";
import { SiteHeader } from "@/components/site-header";
import { DELIVERY_MODES } from "@/lib/catalog";
import { formatNaira } from "@/lib/money";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Listing · Purple Vendra" };

export default function ListingPage({ params }: PageProps<"/l/[id]">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading…</p>}>
        <Listing params={params} />
      </Suspense>
    </main>
  );
}

async function Listing({ params }: { params: PageProps<"/l/[id]">["params"] }) {
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(id)) notFound();
  const supabase = await createClient();
  // RLS: everyone sees approved listings; sellers also see their own.
  const { data: l } = await supabase
    .from("listings")
    .select("*, listing_images(storage_path, position), categories(name), profiles!listings_seller_id_fkey(username, display_name, business_name, is_verified)")
    .eq("id", id)
    .maybeSingle();
  if (!l) notFound();

  const photos = [...(l.listing_images ?? [])].sort(
    (a: { position: number }, b: { position: number }) => a.position - b.position,
  );
  const seller = l.profiles;
  const live = l.status === "approved";

  return (
    <div className="mt-8 grid gap-8 md:grid-cols-2">
      <div className="space-y-2">
        {photos.length === 0 ? (
          <div className="aspect-square rounded-3xl bg-brand-soft" />
        ) : (
          photos.map((p: { storage_path: string }, i: number) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img key={p.storage_path} src={publicFileUrl("listing-images", p.storage_path) ?? ""}
              alt={i === 0 ? l.title : ""} className="w-full rounded-3xl object-cover" loading={i ? "lazy" : "eager"} />
          ))
        )}
      </div>
      <div className="space-y-4">
        {!live && (
          <p className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
            Only you can see this. It goes live once the Purple Vendra team approves it.
          </p>
        )}
        <p className="text-sm text-muted">{l.categories?.name}</p>
        <h1 className="text-3xl font-bold text-brand-strong">{l.title}</h1>
        <p className="text-2xl font-semibold">
          {l.price_is_starting && <span className="text-base font-normal text-muted">From </span>}
          {formatNaira(l.price_kobo)}
        </p>
        <p className="text-sm text-muted">
          {DELIVERY_MODES[l.delivery_mode as keyof typeof DELIVERY_MODES]}
          {l.city || l.state ? ` · ${[l.city, l.state].filter(Boolean).join(", ")}` : ""}
          {l.stock === 0 ? " · Out of stock" : ""}
        </p>
        {live && l.stock !== 0 && <AddToCartButton listingId={l.id} />}
        <p className="whitespace-pre-line text-foreground/90">{l.description}</p>
        {seller && (
          <Link href={`/shop/${seller.username}`}
            className="flex items-center justify-between rounded-2xl border border-border bg-card p-4 hover:border-brand">
            <span>
              <span className="block text-xs text-muted">Sold by</span>
              <span className="font-semibold text-brand-strong">
                {seller.business_name || seller.display_name} {seller.is_verified && <span className="text-green-700">✓</span>}
              </span>
            </span>
            <span className="text-sm font-medium text-brand">Visit shop →</span>
          </Link>
        )}
        <p className="text-xs text-muted">🔒 Pay only through Purple Vendra. Your money is held until you confirm delivery.</p>
        {live && <ReportButton listingId={l.id} />}
      </div>
    </div>
  );
}
