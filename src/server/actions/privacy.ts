"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/server/db/supabase";

/**
 * Asks to delete the account. The database checks the typed username,
 * the 2FA code (if the person uses 2FA), and that no orders or bookings are
 * still in progress. Deletion happens after a 30-day grace period.
 */
export async function requestAccountDeletion(username: string): Promise<{ deleteOn?: string; error?: string }> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("request_account_deletion", { confirm_username: username });
  if (error) return { error: error.message };
  revalidatePath("/account");
  revalidatePath("/account/privacy");
  return { deleteOn: data as string };
}

export async function cancelAccountDeletion(): Promise<{ ok?: true; error?: string }> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("cancel_account_deletion");
  if (error) return { error: error.message };
  revalidatePath("/account");
  revalidatePath("/account/privacy");
  return { ok: true };
}
