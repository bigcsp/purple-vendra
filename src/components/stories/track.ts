"use client";

import { createClient } from "@/lib/supabase/client";

type EventType = "impression" | "view" | "share" | "product_click" | "shop_visit";

/**
 * Anonymous analytics for Purple Stories. Views and impressions count once
 * per story per browser session so refreshing doesn't inflate numbers.
 * The database ignores the seller's own views and checks every id.
 */
export function trackStory(videoId: string, type: EventType, opts: { listingId?: string; campaignId?: string | null } = {}) {
  if (type === "view" || type === "impression") {
    const key = `pv-story-${type}-${videoId}`;
    try {
      if (sessionStorage.getItem(key)) return;
      sessionStorage.setItem(key, "1");
    } catch {
      /* private mode: count anyway */
    }
  }
  void createClient()
    .rpc("record_story_event", {
      p_video: videoId,
      p_type: type,
      p_listing: opts.listingId ?? null,
      p_campaign: opts.campaignId ?? null,
    })
    .then(() => undefined);
}
