import "server-only";

import { LISTING_CARD_SELECT, toListingCard } from "@/lib/catalog";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/lib/supabase/server";

/** The seller's own listings that can be tagged in a story (not removed/rejected). */
export async function getTaggableListings(userId: string) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("listings")
    .select(LISTING_CARD_SELECT)
    .eq("seller_id", userId)
    .in("status", ["approved", "pending", "draft"])
    .order("created_at", { ascending: false });
  return (data ?? []).map((l) => {
    const c = toListingCard(l);
    return { id: c.id, title: c.title, price_kobo: c.price_kobo, status: c.status, image: publicFileUrl("listing-images", c.image) };
  });
}
