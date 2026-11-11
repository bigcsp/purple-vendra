import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCategories } from "@/lib/catalog";
import { requireSeller } from "@/lib/seller";
import { createClient } from "@/lib/supabase/server";
import { getTaggableListings } from "../data";
import { StoryForm } from "../story-form";

export const metadata: Metadata = { title: "Edit story · Purple Vendra" };

export default function EditStoryPage({ params }: PageProps<"/sell/stories/[id]">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <EditStory params={params} />
      </Suspense>
    </PageShell>
  );
}

async function EditStory({ params }: { params: PageProps<"/sell/stories/[id]">["params"] }) {
  const { id } = await params;
  const user = await requireSeller(`/sell/stories/${id}`);
  if (!/^[0-9a-f-]{36}$/i.test(id)) notFound();
  const supabase = await createClient();
  const [{ data: s }, categories, listings] = await Promise.all([
    supabase
      .from("story_videos")
      .select("*, story_video_products(listing_id, position)")
      .eq("id", id)
      .eq("seller_id", user.id)
      .maybeSingle(),
    getCategories(),
    getTaggableListings(user.id),
  ]);
  if (!s) notFound();

  return (
    <Card>
      <Link href="/sell/stories" className="text-sm text-muted hover:text-brand">← Vendra Stories</Link>
      <h1 className="mt-1 mb-6 text-2xl font-bold text-brand-strong">Edit story</h1>
      {s.moderation_note && (
        <p className="mb-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{s.moderation_note}</p>
      )}
      <StoryForm
        userId={user.id}
        categories={categories}
        listings={listings}
        initial={{
          id: s.id,
          title: s.title,
          description: s.description,
          categoryId: s.category_id,
          videoPath: s.video_path,
          thumbnailPath: s.thumbnail_path,
          durationSeconds: s.duration_seconds === null ? null : Number(s.duration_seconds),
          sizeBytes: s.size_bytes,
          width: s.width,
          height: s.height,
          status: s.status,
          productIds: [...(s.story_video_products ?? [])]
            .sort((a: { position: number }, b: { position: number }) => a.position - b.position)
            .map((p: { listing_id: string }) => p.listing_id),
        }}
      />
    </Card>
  );
}
