"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/server/db/supabase";

type Result = { ok?: true; error?: string; signIn?: true; id?: string };

const UUID = /^[0-9a-f-]{36}$/i;

function friendly(message: string) {
  if (/permission denied|row-level/i.test(message)) return "That isn't allowed.";
  return message;
}

/** Opens (or reopens) a chat with a seller, optionally about one listing. */
export async function startConversation(sellerId: string, listingId?: string | null): Promise<Result> {
  if (!UUID.test(sellerId) || (listingId && !UUID.test(listingId))) return { error: "Something went wrong. Please try again." };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signIn: true };

  const { data, error } = await supabase.rpc("start_conversation", { p_seller: sellerId, p_listing: listingId ?? null });
  if (error) return { error: friendly(error.message) };
  return { ok: true, id: data as string };
}

export async function sendMessage(conversationId: string, body: string): Promise<Result> {
  if (!UUID.test(conversationId)) return { error: "Conversation not found." };
  const text = body.trim();
  if (!text) return { error: "Type a message first." };
  if (text.length > 2000) return { error: "Messages can be up to 2,000 characters." };

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("send_message", { p_conversation: conversationId, p_body: text });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/messages/${conversationId}`);
  revalidatePath("/messages");
  return { ok: true, id: data as string };
}

export async function markConversationRead(conversationId: string): Promise<Result> {
  if (!UUID.test(conversationId)) return { error: "Conversation not found." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("mark_conversation_read", { p_conversation: conversationId });
  if (error) return { error: friendly(error.message) };
  return { ok: true };
}

export async function archiveConversation(conversationId: string, archived: boolean): Promise<Result> {
  if (!UUID.test(conversationId)) return { error: "Conversation not found." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("archive_conversation", { p_conversation: conversationId, p_archived: archived });
  if (error) return { error: friendly(error.message) };
  revalidatePath("/messages");
  return { ok: true };
}

export async function setBlocked(userId: string, blocked: boolean, conversationId?: string): Promise<Result> {
  if (!UUID.test(userId)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_user_block", { p_user: userId, p_blocked: blocked });
  if (error) return { error: friendly(error.message) };
  if (conversationId) revalidatePath(`/messages/${conversationId}`);
  revalidatePath("/messages");
  return { ok: true };
}
