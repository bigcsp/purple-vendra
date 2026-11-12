import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCategories } from "@/server/queries/catalog";
import { requireSeller } from "@/server/auth/seller";
import { getTaggableListings } from "../data";
import { StoryForm } from "../story-form";

export const metadata: Metadata = { title: "New story · Purple Shop" };

export default function NewStoryPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <NewStory />
      </Suspense>
    </PageShell>
  );
}

async function NewStory() {
  const user = await requireSeller("/sell/stories/new");
  const [categories, listings] = await Promise.all([getCategories(), getTaggableListings(user.id)]);
  return (
    <Card>
      <Link href="/sell/stories" className="text-sm text-muted hover:text-brand">← Purple Stories</Link>
      <h1 className="mt-1 mb-6 text-2xl font-bold text-brand-strong">Post a story</h1>
      <StoryForm userId={user.id} categories={categories} listings={listings} />
    </Card>
  );
}
