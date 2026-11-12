import "server-only";

import { LISTING_CARD_SELECT, toListingCard } from "@/server/queries/catalog";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/server/db/supabase";

/** Everything the Purple Stories player needs for one video. */
export type StoryItem = {
  id: string;
  title: string;
  description: string;
  videoUrl: string;
  posterUrl: string | null;
  viewCount: number;
  likeCount: number;
  commentCount: number;
  campaignId: string | null;
  seller: { id: string; username: string; name: string; verified: boolean };
  products: { id: string; title: string; priceKobo: number; priceIsStarting: boolean; image: string | null }[];
};

type ProductRow = { position: number; listings: Parameters<typeof toListingCard>[0] | null };

function productsOf(rows: ProductRow[] | null | undefined) {
  return [...(rows ?? [])]
    .sort((a, b) => a.position - b.position)
    .filter((r) => r.listings && r.listings.status === "approved")
    .map((r) => {
      const c = toListingCard(r.listings!);
      return {
        id: c.id,
        title: c.title,
        priceKobo: c.price_kobo,
        priceIsStarting: c.price_is_starting,
        image: publicFileUrl("listing-images", c.image),
      };
    });
}

const STORY_SELECT = `id, title, description, video_path, thumbnail_path, view_count, like_count, comment_count, seller_id,
  story_video_products(position, listings(${LISTING_CARD_SELECT}))`;

/** Published stories on one seller's shop page (RLS hides drafts and hidden stories). */
export async function getShopStories(
  seller: StoryItem["seller"],
): Promise<StoryItem[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("story_videos")
    .select(STORY_SELECT)
    .eq("seller_id", seller.id)
    .eq("status", "published")
    .order("published_at", { ascending: false })
    .limit(30);
  return (data ?? []).map((v) => ({
    id: v.id,
    title: v.title,
    description: v.description,
    videoUrl: publicFileUrl("story-media", v.video_path)!,
    posterUrl: publicFileUrl("story-media", v.thumbnail_path),
    viewCount: v.view_count,
    likeCount: v.like_count,
    commentCount: v.comment_count,
    campaignId: null,
    seller,
    products: productsOf(v.story_video_products as unknown as ProductRow[]),
  }));
}

type FeedRow = {
  video_id: string;
  seller_id: string;
  seller_username: string;
  seller_name: string;
  seller_verified: boolean;
  campaign_id: string | null;
};

/** Turns feed/search rows (ids + seller) into full stories, keeping their order. */
async function loadStories(rows: FeedRow[]): Promise<StoryItem[]> {
  if (rows.length === 0) return [];
  const supabase = await createClient();
  const { data: details } = await supabase
    .from("story_videos")
    .select(STORY_SELECT)
    .in("id", rows.map((r) => r.video_id));
  const byId = new Map((details ?? []).map((d) => [d.id as string, d]));

  return rows.flatMap((r) => {
    const v = byId.get(r.video_id);
    if (!v) return [];
    return [
      {
        id: v.id,
        title: v.title,
        description: v.description,
        videoUrl: publicFileUrl("story-media", v.video_path)!,
        posterUrl: publicFileUrl("story-media", v.thumbnail_path),
        viewCount: v.view_count,
        likeCount: v.like_count,
        commentCount: v.comment_count,
        campaignId: r.campaign_id,
        seller: { id: r.seller_id, username: r.seller_username, name: r.seller_name, verified: r.seller_verified },
        products: productsOf(v.story_video_products as unknown as ProductRow[]),
      },
    ];
  });
}

/** Discovery feed: live promoted stories for this viewer first, then newest. */
export async function getFeedStories(categoryId: number | null): Promise<StoryItem[]> {
  const supabase = await createClient();
  const { data: feed } = await supabase.rpc("get_story_feed", { p_category: categoryId, p_limit: 36 });
  return loadStories((feed ?? []) as FeedRow[]);
}

/** One published story by id (for links from search suggestions). */
export async function getStoryById(id: string): Promise<StoryItem | null> {
  if (!/^[0-9a-f-]{36}$/i.test(id)) return null;
  const supabase = await createClient();
  const { data } = await supabase
    .from("story_videos")
    .select("id, seller_id, profiles!story_videos_seller_id_fkey(username, display_name, business_name, is_verified)")
    .eq("id", id)
    .eq("status", "published")
    .maybeSingle();
  if (!data) return null;
  const p = data.profiles as unknown as { username: string; display_name: string; business_name: string | null; is_verified: boolean } | null;
  if (!p) return null;
  const [story] = await loadStories([
    {
      video_id: data.id,
      seller_id: data.seller_id,
      seller_username: p.username,
      seller_name: p.business_name || p.display_name,
      seller_verified: p.is_verified,
      campaign_id: null,
    },
  ]);
  return story ?? null;
}

/** Stories whose title, description, seller or synonyms match the search. */
export async function searchStories(q: string, limit = 8): Promise<StoryItem[]> {
  if (!q) return [];
  const supabase = await createClient();
  const { data } = await supabase.rpc("search_stories", { p_query: q, p_limit: limit });
  return loadStories((data ?? []) as FeedRow[]);
}

export const STORY_STATUS: Record<string, { text: string; tone: string }> = {
  draft: { text: "Draft", tone: "bg-gray-100 text-gray-700" },
  published: { text: "Published", tone: "bg-green-100 text-green-800" },
  hidden: { text: "Hidden for review", tone: "bg-red-100 text-red-700" },
  removed: { text: "Removed by Purple Shop", tone: "bg-gray-100 text-gray-500" },
};

export const CAMPAIGN_STATUS: Record<string, { text: string; tone: string }> = {
  awaiting_payment: { text: "Awaiting payment", tone: "bg-amber-100 text-amber-800" },
  active: { text: "Running", tone: "bg-green-100 text-green-800" },
  paused: { text: "Paused", tone: "bg-gray-100 text-gray-700" },
  completed: { text: "Finished", tone: "bg-brand-soft text-brand" },
  cancelled: { text: "Cancelled", tone: "bg-gray-100 text-gray-500" },
  rejected: { text: "Not approved", tone: "bg-red-100 text-red-700" },
};
