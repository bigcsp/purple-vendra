"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/server/db/supabase";

type Result = { ok?: true; error?: string; signIn?: true };

/** Save or unsave a listing for the signed-in person. */
export async function setSaved(listingId: string, saved: boolean): Promise<Result> {
  if (!/^[0-9a-f-]{36}$/i.test(listingId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signIn: true };

  if (saved) {
    const { error } = await supabase
      .from("saves")
      .upsert({ user_id: user.id, listing_id: listingId }, { onConflict: "user_id,listing_id", ignoreDuplicates: true });
    if (error) {
      if (/row-level/i.test(error.message)) return { error: "This item can't be saved (it may be yours or no longer available)." };
      return { error: error.message };
    }
  } else {
    const { error } = await supabase.from("saves").delete().eq("user_id", user.id).eq("listing_id", listingId);
    if (error) return { error: error.message };
  }
  revalidatePath("/saved");
  return { ok: true };
}
