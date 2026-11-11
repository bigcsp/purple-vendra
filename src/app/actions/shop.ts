"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

type Result = { ok?: true; error?: string; signIn?: true };

async function signedIn() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return { supabase, user };
}

export async function addToCart(listingId: string): Promise<Result> {
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true, error: "Please sign in to add to your cart." };
  const { error } = await supabase
    .from("cart_items")
    .upsert({ user_id: user.id, listing_id: listingId, quantity: 1 }, { onConflict: "user_id,listing_id", ignoreDuplicates: true });
  if (error) {
    if (/row-level security/i.test(error.message)) return { error: "This item can't be added (it may be yours or no longer available)." };
    return { error: error.message };
  }
  revalidatePath("/cart");
  return { ok: true };
}

export async function setCartQuantity(listingId: string, quantity: number): Promise<Result> {
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true };
  if (quantity < 1) {
    await supabase.from("cart_items").delete().eq("user_id", user.id).eq("listing_id", listingId);
  } else {
    const { error } = await supabase
      .from("cart_items")
      .update({ quantity: Math.min(99, Math.floor(quantity)) })
      .eq("user_id", user.id)
      .eq("listing_id", listingId);
    if (error) return { error: error.message };
  }
  revalidatePath("/cart");
  return { ok: true };
}

export async function toggleFollow(sellerId: string, follow: boolean): Promise<Result> {
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true, error: "Please sign in to follow sellers." };
  if (user.id === sellerId) return { error: "That's your own shop." };
  const { error } = follow
    ? await supabase.from("follows").upsert({ follower_id: user.id, seller_id: sellerId }, { ignoreDuplicates: true })
    : await supabase.from("follows").delete().eq("follower_id", user.id).eq("seller_id", sellerId);
  if (error) return { error: error.message };
  return { ok: true };
}
