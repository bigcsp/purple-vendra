import "server-only";

import { createClient } from "@/lib/supabase/server";

export type BoardRequest = {
  id: string;
  title: string;
  description: string;
  category_id: number;
  budget_kobo: number | null;
  state: string;
  city: string | null;
  deadline: string | null;
  created_at: string;
  expires_at: string;
  offer_count: number;
  is_full: boolean;
  you_offered: boolean;
  total_count: number;
};

export type RequestDetail = {
  id: string;
  title: string;
  description: string;
  category_id: number;
  budget_kobo: number | null;
  state: string;
  city: string | null;
  deadline: string | null;
  status: "open" | "closed" | "expired";
  created_at: string;
  expires_at: string;
  offer_count: number;
  is_full: boolean;
  is_owner: boolean;
  buyer_username: string | null;
  my_offer_id: string | null;
  my_offer_status: OfferStatus | null;
  my_offer_price_kobo: number | null;
  my_offer_days: number | null;
  my_offer_message: string | null;
  my_offer_listing: string | null;
  chat_id: string | null;
};

export type OfferStatus = "sent" | "accepted" | "declined" | "withdrawn";

export type RequestOffer = {
  id: string;
  status: OfferStatus;
  price_kobo: number;
  delivery_days: number | null;
  message: string;
  created_at: string;
  updated_at: string;
  seller_id: string;
  seller_username: string;
  seller_name: string;
  seller_avatar: string | null;
  seller_verified: boolean;
  seller_rating: number | null;
  seller_rating_count: number;
  seller_state: string | null;
  listing_id: string | null;
  listing_title: string | null;
  chat_id: string | null;
};

export const BOARD_PAGE_SIZE = 24;

export async function getBoard(opts: {
  q?: string;
  categoryId?: number | null;
  state?: string | null;
  matches?: boolean;
  page?: number;
}): Promise<{ requests: BoardRequest[]; total: number }> {
  const supabase = await createClient();
  const page = Math.max(1, opts.page ?? 1);
  const { data, error } = await supabase.rpc("get_request_board", {
    p_query: opts.q || null,
    p_category: opts.categoryId ?? null,
    p_state: opts.state || null,
    p_matches: !!opts.matches,
    p_limit: BOARD_PAGE_SIZE,
    p_offset: (page - 1) * BOARD_PAGE_SIZE,
  });
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as BoardRequest[];
  return { requests: rows, total: rows[0] ? Number(rows[0].total_count) : 0 };
}

export async function getRequest(id: string): Promise<RequestDetail | null> {
  if (!/^[0-9a-f-]{36}$/i.test(id)) return null;
  const supabase = await createClient();
  const { data } = await supabase.rpc("get_request", { p_request: id }).maybeSingle();
  return (data as RequestDetail | null) ?? null;
}

export async function getOffers(requestId: string): Promise<RequestOffer[]> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("get_request_offers", { p_request: requestId });
  return (data ?? []) as RequestOffer[];
}

export type MyRequest = {
  id: string;
  title: string;
  status: "open" | "closed" | "expired";
  offer_count: number;
  new_offers: number;
  created_at: string;
  expires_at: string;
};
export type MyOffer = {
  offer_id: string;
  request_id: string;
  title: string;
  offer_status: OfferStatus;
  request_status: "open" | "closed" | "expired";
  price_kobo: number;
  created_at: string;
  chat_id: string | null;
};

export async function getMine(): Promise<{ requests: MyRequest[]; offers: MyOffer[] }> {
  const supabase = await createClient();
  const [{ data: requests }, { data: offers }] = await Promise.all([supabase.rpc("my_requests"), supabase.rpc("my_offers")]);
  return { requests: (requests ?? []) as MyRequest[], offers: (offers ?? []) as MyOffer[] };
}

/** "3 days left", "Ends today", "Ended". */
export function timeLeft(iso: string): string {
  const ms = new Date(iso).getTime() - Date.now();
  if (ms <= 0) return "Ended";
  const days = Math.floor(ms / 86_400_000);
  if (days >= 1) return `${days} day${days === 1 ? "" : "s"} left`;
  const hours = Math.floor(ms / 3_600_000);
  return hours >= 1 ? `${hours}h left` : "Ends soon";
}

export function postedAgo(iso: string): string {
  const mins = Math.floor((Date.now() - new Date(iso).getTime()) / 60_000);
  if (mins < 60) return mins <= 1 ? "Just now" : `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return days === 1 ? "Yesterday" : `${days} days ago`;
}
