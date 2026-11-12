import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCurrentUser } from "@/server/auth/session";
import { formatNaira } from "@/lib/money";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/server/db/supabase";
import { CartQuantity } from "./cart-quantity";

export const metadata: Metadata = { title: "Your cart · Purple Shop" };

export default function CartPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your cart…</p>}>
        <Cart />
      </Suspense>
    </PageShell>
  );
}

type Row = {
  listing_id: string;
  quantity: number;
  listings: {
    id: string;
    title: string;
    price_kobo: number;
    status: string;
    seller_id: string;
    listing_images: { storage_path: string; position: number }[];
    profiles: { username: string; display_name: string; business_name: string | null } | null;
  } | null;
};

async function Cart() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/cart");
  const supabase = await createClient();
  const { data } = await supabase
    .from("cart_items")
    .select("listing_id, quantity, listings(id, title, price_kobo, status, seller_id, listing_images(storage_path, position), profiles!listings_seller_id_fkey(username, display_name, business_name))")
    .eq("user_id", user.id)
    .order("added_at", { ascending: false });
  const rows = ((data ?? []) as unknown as Row[]).filter((r) => r.listings);

  // One escrow order per seller at checkout, so group by shop.
  const shops = new Map<string, Row[]>();
  for (const r of rows) {
    const key = r.listings!.seller_id;
    shops.set(key, [...(shops.get(key) ?? []), r]);
  }
  const total = rows
    .filter((r) => r.listings!.status === "approved")
    .reduce((sum, r) => sum + r.listings!.price_kobo * r.quantity, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-brand-strong">Your cart</h1>
      {rows.length === 0 ? (
        <Card>
          <p className="text-sm text-muted">Your cart is empty. Find something you love in <Link href="/stories" className="text-brand underline">Purple Stories</Link>.</p>
        </Card>
      ) : (
        <>
          {[...shops.values()].map((items) => {
            const seller = items[0].listings!.profiles;
            return (
              <Card key={items[0].listings!.seller_id}>
                {seller && (
                  <Link href={`/shop/${seller.username}`} className="text-sm font-semibold text-brand-strong hover:underline">
                    {seller.business_name || seller.display_name}
                  </Link>
                )}
                <ul className="mt-3 divide-y divide-border">
                  {items.map((r) => {
                    const l = r.listings!;
                    const img = [...l.listing_images].sort((a, b) => a.position - b.position)[0];
                    return (
                      <li key={l.id} className="flex items-center gap-3 py-3">
                        {img ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={publicFileUrl("listing-images", img.storage_path) ?? ""} alt="" className="h-16 w-16 rounded-xl object-cover" />
                        ) : (
                          <div className="h-16 w-16 rounded-xl bg-brand-soft" />
                        )}
                        <div className="min-w-0 flex-1">
                          <Link href={`/l/${l.id}`} className="block truncate font-medium hover:text-brand">{l.title}</Link>
                          {l.status === "approved" ? (
                            <p className="text-sm">{formatNaira(l.price_kobo)}</p>
                          ) : (
                            <p className="text-sm text-red-700">No longer available</p>
                          )}
                        </div>
                        <CartQuantity listingId={l.id} quantity={r.quantity} />
                      </li>
                    );
                  })}
                </ul>
              </Card>
            );
          })}
          <Card>
            <div className="flex items-center justify-between">
              <span className="font-medium">Total</span>
              <span className="text-xl font-bold text-brand-strong">{formatNaira(total)}</span>
            </div>
            <p className="mt-2 text-sm text-muted">
              Secure checkout with payment held until delivery is being added next (backend step 7). Your cart is saved
              to your account until then.
            </p>
          </Card>
        </>
      )}
    </div>
  );
}
