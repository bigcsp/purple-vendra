import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { MessageButton } from "@/components/messages/message-button";
import { RecentlyViewed, RememberView } from "@/components/recently-viewed";
import { ReportButton } from "@/components/report-button";
import { SaveButton } from "@/components/save-button";
import { AddToCartButton } from "@/components/shop-buttons";
import { SiteHeader } from "@/components/site-header";
import { getCurrentUser } from "@/server/auth/session";
import { DELIVERY_MODES } from "@/server/queries/catalog";
import { formatNaira } from "@/lib/money";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/server/db/supabase";

export const metadata: Metadata = { title: "Listing · Purple Shop" };

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
  const viewer = await getCurrentUser();
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
    <>
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
            Only you can see this. It goes live once the Purple Shop team approves it.
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
        {live && (
          <div className="grid grid-cols-2 gap-2">
            {l.stock !== 0 && <AddToCartButton listingId={l.id} className="col-span-2" />}
            {viewer?.id !== l.seller_id && (
              <>
                <MessageButton sellerId={l.seller_id} listingId={l.id} label="Ask the seller" />
                <SaveButton listingId={l.id} />
              </>
            )}
          </div>
        )}
        {live && (
          <RememberView
            item={{
              id: l.id,
              title: l.title,
              priceKobo: l.price_kobo,
              priceIsStarting: l.price_is_starting,
              image: photos[0] ? publicFileUrl("listing-images", photos[0].storage_path) : null,
              seller: seller ? seller.business_name || seller.display_name : null,
            }}
          />
        )}
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
        <p className="rounded-xl bg-brand-soft/60 px-3 py-2 text-xs text-brand-strong">
          🔒 Pay only through Purple Shop escrow. Your money is held until you confirm delivery. Never pay a seller by
          transfer, cash or another app. <Link href="/safety" className="underline">Stay safe</Link>
        </p>
        {live && <ReportButton listingId={l.id} />}
      </div>
    </div>
    <div className="mt-12">
      <RecentlyViewed excludeId={l.id} title="You looked at these too" />
    </div>
    </>
  );
}
