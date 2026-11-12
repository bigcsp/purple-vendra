"use client";

import { useEffect, useRef, useState } from "react";
import type { StoryItem } from "@/lib/stories";
import { StoryViewer } from "./story-viewer";
import { trackStory } from "./track";

/**
 * Purple Stories grid: 9:16 cards that open a full-screen player.
 * Used on shop pages (one seller) and the /stories discovery feed.
 */
export function StoryGallery({
  stories,
  viewerId,
  initialStoryId,
  showSeller = false,
}: {
  stories: StoryItem[];
  viewerId: string | null;
  initialStoryId?: string;
  showSeller?: boolean;
}) {
  const start = initialStoryId ? stories.findIndex((s) => s.id === initialStoryId) : -1;
  const [open, setOpen] = useState<number | null>(start >= 0 ? start : null);

  return (
    <>
      <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {stories.map((s, i) => (
          <StoryCard key={s.id} story={s} showSeller={showSeller} onOpen={() => setOpen(i)} />
        ))}
      </ul>
      {open !== null && (
        <StoryViewer stories={stories} index={open} onIndex={setOpen} onClose={() => setOpen(null)} viewerId={viewerId} />
      )}
    </>
  );
}

function StoryCard({ story, showSeller, onOpen }: { story: StoryItem; showSeller: boolean; onOpen: () => void }) {
  const ref = useRef<HTMLLIElement>(null);

  // Promoted stories count an impression when the card is actually seen.
  useEffect(() => {
    if (!story.campaignId || !ref.current) return;
    const el = ref.current;
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          trackStory(story.id, "impression", { campaignId: story.campaignId });
          io.disconnect();
        }
      },
      { threshold: 0.6 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [story.id, story.campaignId]);

  return (
    <li ref={ref}>
      <button onClick={onOpen}
        className="group relative block aspect-[9/16] w-full overflow-hidden rounded-2xl bg-panel text-left shadow-sm ring-brand transition hover:ring-2 focus-visible:ring-2">
        {story.posterUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={story.posterUrl} alt="" loading="lazy" className="h-full w-full object-cover transition group-hover:scale-[1.02]" />
        ) : (
          <video src={`${story.videoUrl}#t=0.5`} preload="metadata" muted playsInline className="h-full w-full object-cover" />
        )}
        <span className="absolute inset-0 bg-gradient-to-t from-black/75 via-transparent to-transparent" />
        {story.campaignId && (
          <span className="absolute left-2 top-2 rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold text-brand-strong">
            Promoted
          </span>
        )}
        {story.products.length > 0 && (
          <span className="absolute right-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-[10px] font-semibold text-brand-strong">
            🛍 {story.products.length}
          </span>
        )}
        <span className="absolute inset-x-0 bottom-0 p-3 text-white">
          {showSeller && (
            <span className="block truncate text-xs text-white/80">
              @{story.seller.username} {story.seller.verified && "✓"}
            </span>
          )}
          <span className="line-clamp-2 text-sm font-semibold leading-tight">{story.title}</span>
          <span className="mt-1 block text-xs text-white/80">▶ {story.viewCount.toLocaleString()} · ♥ {story.likeCount.toLocaleString()}</span>
        </span>
      </button>
    </li>
  );
}
