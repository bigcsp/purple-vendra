"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type StoryInput = {
  id: string;
  title: string;
  description: string;
  categoryId: number;
  videoPath: string;
  thumbnailPath: string | null;
  durationSeconds: number | null;
  sizeBytes: number | null;
  width: number | null;
  height: number | null;
  productIds: string[];
  publish: boolean;
};

type Result = { ok?: true; id?: string; error?: string };

function friendly(message: string) {
  if (/2FA|row-level security/i.test(message))
    return "Not allowed. Make sure you're signed in as a seller with your 2FA code.";
  if (/title/i.test(message) && /check/i.test(message)) return "Title: 3–120 characters.";
  return message;
}

function validate(input: StoryInput) {
  const title = input.title.trim();
  if (title.length < 3 || title.length > 120) return "Title: 3–120 characters.";
  if (input.description.length > 2000) return "Description: up to 2,000 characters.";
  if (!Number.isInteger(input.categoryId)) return "Choose a category.";
  if (input.productIds.length > 6) return "You can tag up to 6 products.";
  if (!/^[0-9a-f-]{36}$/i.test(input.id)) return "Something went wrong. Refresh and try again.";
  return null;
}

async function syncProducts(supabase: Awaited<ReturnType<typeof createClient>>, videoId: string, productIds: string[]) {
  const { error: delError } = await supabase.from("story_video_products").delete().eq("video_id", videoId);
  if (delError) return delError.message;
  if (productIds.length === 0) return null;
  const { error } = await supabase
    .from("story_video_products")
    .insert(productIds.map((listing_id, position) => ({ video_id: videoId, listing_id, position })));
  return error?.message ?? null;
}

export async function createStory(input: StoryInput): Promise<Result> {
  const invalid = validate(input);
  if (invalid) return { error: invalid };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Please sign in again." };

  const { error } = await supabase.from("story_videos").insert({
    id: input.id,
    seller_id: user.id,
    title: input.title.trim(),
    description: input.description.trim(),
    category_id: input.categoryId,
    video_path: input.videoPath,
    thumbnail_path: input.thumbnailPath,
    duration_seconds: input.durationSeconds ? Math.round(input.durationSeconds * 10) / 10 : null,
    size_bytes: input.sizeBytes,
    width: input.width,
    height: input.height,
    status: input.publish ? "published" : "draft",
  });
  if (error) {
    // Don't leave orphaned files behind if the save failed.
    await supabase.storage.from("story-media").remove([input.videoPath, input.thumbnailPath].filter(Boolean) as string[]);
    return { error: friendly(error.message) };
  }
  const productError = await syncProducts(supabase, input.id, input.productIds);
  revalidatePath("/sell/stories");
  if (productError) return { id: input.id, error: `Story saved, but products couldn't be tagged: ${friendly(productError)}` };
  return { ok: true, id: input.id };
}

export async function updateStory(input: StoryInput): Promise<Result> {
  const invalid = validate(input);
  if (invalid) return { error: invalid };
  const supabase = await createClient();
  const { data: current } = await supabase.from("story_videos").select("status").eq("id", input.id).maybeSingle();
  if (!current) return { error: "Story not found." };

  const patch: Record<string, unknown> = {
    title: input.title.trim(),
    description: input.description.trim(),
    category_id: input.categoryId,
    video_path: input.videoPath,
    thumbnail_path: input.thumbnailPath,
    duration_seconds: input.durationSeconds ? Math.round(input.durationSeconds * 10) / 10 : null,
    size_bytes: input.sizeBytes,
    width: input.width,
    height: input.height,
  };
  if (current.status === "draft" || current.status === "published") patch.status = input.publish ? "published" : "draft";

  const { error } = await supabase.from("story_videos").update(patch).eq("id", input.id);
  if (error) return { error: friendly(error.message) };
  const productError = await syncProducts(supabase, input.id, input.productIds);
  revalidatePath("/sell/stories");
  if (productError) return { id: input.id, error: `Saved, but products couldn't be tagged: ${friendly(productError)}` };
  return { ok: true, id: input.id };
}

export async function setStoryPublished(id: string, publish: boolean): Promise<Result> {
  const supabase = await createClient();
  const { error, count } = await supabase
    .from("story_videos")
    .update({ status: publish ? "published" : "draft" }, { count: "exact" })
    .eq("id", id)
    .in("status", ["draft", "published"]);
  if (error) return { error: friendly(error.message) };
  if (!count) return { error: "This story can't be changed right now." };
  revalidatePath("/sell/stories");
  return { ok: true };
}

export async function deleteStory(id: string): Promise<Result> {
  const supabase = await createClient();
  const { data: story } = await supabase.from("story_videos").select("video_path, thumbnail_path").eq("id", id).maybeSingle();
  if (!story) return { error: "Story not found." };
  const { error, count } = await supabase.from("story_videos").delete({ count: "exact" }).eq("id", id);
  if (error) return { error: friendly(error.message) };
  if (!count) return { error: "Story not found." };
  // Remove files now; the nightly cleanup also has them queued as a backup.
  await supabase.storage.from("story-media").remove([story.video_path, story.thumbnail_path].filter(Boolean) as string[]);
  revalidatePath("/sell/stories");
  return { ok: true };
}

/** A buyer adds a product they saw in a story to their cart (remembers the story for sales tracking). */
export async function addStoryProductToCart(videoId: string, listingId: string, campaignId: string | null): Promise<Result & { signIn?: true }> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signIn: true, error: "Please sign in to add to your cart." };
  const { error } = await supabase.rpc("add_story_product_to_cart", {
    p_video: videoId,
    p_listing: listingId,
    p_campaign: campaignId,
  });
  if (error) return { error: error.message };
  revalidatePath("/cart");
  return { ok: true };
}
