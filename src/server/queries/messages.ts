import "server-only";

import { createClient } from "@/server/db/supabase";

export type InboxRow = {
  id: string;
  you_are: "buyer" | "seller";
  other_id: string;
  other_username: string;
  other_name: string;
  other_avatar: string | null;
  listing_id: string | null;
  listing_title: string | null;
  last_message: string | null;
  last_from_you: boolean | null;
  last_message_at: string;
  unread: number;
  blocked: boolean;
};

export type ConversationHeader = {
  id: string;
  you_are: "buyer" | "seller";
  other_id: string;
  other_username: string;
  other_name: string;
  other_avatar: string | null;
  other_is_seller: boolean;
  listing_id: string | null;
  listing_title: string | null;
  listing_price_kobo: number | null;
  you_blocked: boolean;
  blocked: boolean;
  other_available: boolean;
};

export type ChatMessage = { id: string; sender_id: string; body: string; created_at: string; read_at: string | null };

export async function getInbox(archived = false): Promise<InboxRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("get_inbox", { p_archived: archived });
  if (error) throw new Error(error.message);
  return (data ?? []) as InboxRow[];
}

export async function getConversation(id: string) {
  const supabase = await createClient();
  const [{ data: header }, { data: messages }] = await Promise.all([
    supabase.rpc("get_conversation", { p_conversation: id }).maybeSingle(),
    supabase
      .from("messages")
      .select("id, sender_id, body, created_at, read_at")
      .eq("conversation_id", id)
      .order("created_at", { ascending: true })
      .limit(500),
  ]);
  if (!header) return null;
  return { header: header as ConversationHeader, messages: (messages ?? []) as ChatMessage[] };
}

export async function getUnreadCount(): Promise<number> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("unread_message_count");
  return typeof data === "number" ? data : 0;
}
