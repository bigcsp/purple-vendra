import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCategories } from "@/lib/catalog";
import { requireSeller } from "@/lib/seller";
import { ListingForm } from "../listing-form";

export const metadata: Metadata = { title: "New listing · Purple Vendra" };

export default function NewListingPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <NewListing />
      </Suspense>
    </PageShell>
  );
}

async function NewListing() {
  const user = await requireSeller("/sell/listings/new");
  const categories = await getCategories();
  return (
    <Card>
      <Link href="/sell/listings" className="text-sm text-muted hover:text-brand">← Your listings</Link>
      <h1 className="mt-1 mb-6 text-2xl font-bold text-brand-strong">New listing</h1>
      <ListingForm userId={user.id} categories={categories} />
    </Card>
  );
}
