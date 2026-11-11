import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCategories } from "@/lib/catalog";
import { requireSeller } from "@/lib/seller";
import { createClient } from "@/lib/supabase/server";
import { ListingForm } from "../listing-form";

export const metadata: Metadata = { title: "Edit listing · Purple Vendra" };

export default function EditListingPage({ params }: PageProps<"/sell/listings/[id]">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <EditListing params={params} />
      </Suspense>
    </PageShell>
  );
}

async function EditListing({ params }: { params: PageProps<"/sell/listings/[id]">["params"] }) {
  const { id } = await params;
  const user = await requireSeller(`/sell/listings/${id}`);
  const supabase = await createClient();
  const [{ data: l }, categories] = await Promise.all([
    supabase
      .from("listings")
      .select("*, listing_images(id, storage_path, position)")
      .eq("id", id)
      .eq("seller_id", user.id)
      .maybeSingle(),
    getCategories(),
  ]);
  if (!l) notFound();

  const photos = [...(l.listing_images ?? [])].sort(
    (a: { position: number }, b: { position: number }) => a.position - b.position,
  );

  return (
    <Card>
      <Link href="/sell/listings" className="text-sm text-muted hover:text-brand">← Your listings</Link>
      <h1 className="mt-1 mb-6 text-2xl font-bold text-brand-strong">Edit listing</h1>
      <ListingForm
        userId={user.id}
        categories={categories}
        photos={photos}
        initial={{
          id: l.id,
          status: l.status,
          title: l.title,
          description: l.description,
          type: l.type,
          categoryId: l.category_id,
          price: String(l.price_kobo / 100),
          priceIsStarting: l.price_is_starting,
          deliveryMode: l.delivery_mode,
          state: l.state ?? "",
          city: l.city ?? "",
          stock: l.stock === null ? "" : String(l.stock),
        }}
      />
    </Card>
  );
}
