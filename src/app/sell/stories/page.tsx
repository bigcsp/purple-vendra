import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { SiteHeader } from "@/components/site-header";
import { Card, Notice, buttonClass } from "@/components/ui";
import { requireSeller } from "@/server/auth/seller";
import { publicFileUrl } from "@/lib/storage-url";
import { STORY_STATUS } from "@/server/queries/stories";
import { createClient } from "@/server/db/supabase";
import { PublishToggle } from "./publish-toggle";

export const metadata: Metadata = { title: "Purple Stories · Seller hub" };

export default function SellerStoriesPage({ searchParams }: PageProps<"/sell/stories">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading your stories…</p>}>
        <MyStories searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function MyStories({ searchParams }: { searchParams: PageProps<"/sell/stories">["searchParams"] }) {
  const user = await requireSeller("/sell/stories");
  const { saved, warn } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase
    .from("story_videos")
    .select("id, title, status, thumbnail_path, view_count, like_count, comment_count, share_count, created_at, story_video_products(listing_id)")
    .eq("seller_id", user.id)
    .order("created_at", { ascending: false });
  const stories = data ?? [];

  return (
    <div className="mt-10 space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <Link href="/sell" className="text-sm text-muted hover:text-brand">← Seller hub</Link>
          <h1 className="text-2xl font-bold text-brand-strong">Purple Stories</h1>
          <p className="text-sm text-muted">Short videos on your shop page. Tag products so buyers can shop while they watch.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Link href="/sell/stories/analytics" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            Analytics
          </Link>
          <Link href="/sell/stories/promote" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            Campaigns
          </Link>
          <Link href="/sell/stories/new" className={`${buttonClass} sm:w-auto`}>+ Post a story</Link>
        </div>
      </div>

      {saved === "published" && <Notice tone="success">Published! It&apos;s live on your shop page now.</Notice>}
      {saved === "draft" && <Notice tone="success">Saved as a draft. Only you can see it.</Notice>}
      {warn === "products" && <Notice tone="error">Some products couldn&apos;t be tagged. Open the story to try again.</Notice>}

      {stories.length === 0 ? (
        <Card>
          <p className="text-sm text-muted">
            No stories yet. Show how you make things, a finished piece, or a happy customer. Buyers who watch are more
            likely to buy.
          </p>
          <Link href="/sell/stories/new" className={`${buttonClass} mt-4 sm:w-auto`}>Post your first story</Link>
        </Card>
      ) : (
        <ul className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {stories.map((s) => {
            const status = STORY_STATUS[s.status] ?? STORY_STATUS.draft;
            const poster = publicFileUrl("story-media", s.thumbnail_path);
            return (
              <li key={s.id} className="overflow-hidden rounded-2xl border border-border bg-card">
                <Link href={`/sell/stories/${s.id}`} className="relative block aspect-[9/16] bg-panel">
                  {poster && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={poster} alt="" className="h-full w-full object-cover" loading="lazy" />
                  )}
                  <span className={`absolute left-2 top-2 rounded-full px-2 py-0.5 text-xs ${status.tone}`}>{status.text}</span>
                  <span className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 p-2 text-xs text-white">
                    ▶ {s.view_count} · ♥ {s.like_count} · 💬 {s.comment_count} · ↗ {s.share_count}
                  </span>
                </Link>
                <div className="space-y-2 p-3">
                  <p className="line-clamp-2 text-sm font-medium">{s.title}</p>
                  <p className="text-xs text-muted">{s.story_video_products?.length ?? 0} products tagged</p>
                  <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs font-medium">
                    <Link href={`/sell/stories/${s.id}`} className="text-brand hover:underline">Edit</Link>
                    {(s.status === "draft" || s.status === "published") && (
                      <PublishToggle id={s.id} published={s.status === "published"} />
                    )}
                    {s.status === "published" && (
                      <>
                        <Link href={`/sell/stories/promote?video=${s.id}`} className="text-accent hover:underline">Promote</Link>
                        <Link href={`/shop/${user.username}?story=${s.id}`} className="text-muted hover:underline">View</Link>
                      </>
                    )}
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
