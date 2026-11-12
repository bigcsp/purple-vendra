import "server-only";

import { createClient } from "@/server/db/supabase";

export type Milestone =
  | "signed_up"
  | "two_factor_on"
  | "shop_opened"
  | "profile_completed"
  | "first_listing_approved"
  | "id_verified"
  | "bank_verified"
  | "first_sale"
  | "first_payout";

export type SellerProgress = {
  sellerNumber: string; // PS-000001
  joinedAt: string;
  steps: { milestone: Milestone; reachedAt: string | null }[];
};

/** The signed-in seller's permanent record: seller number and onboarding timeline. */
export async function getMySellerProgress(): Promise<SellerProgress | null> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_seller_progress");
  const rows = (data ?? []) as { seller_no: number; joined_at: string; milestone: Milestone; reached_at: string | null }[];
  if (rows.length === 0) return null;
  return {
    sellerNumber: `PS-${String(rows[0].seller_no).padStart(6, "0")}`,
    joinedAt: rows[0].joined_at,
    steps: rows.map((r) => ({ milestone: r.milestone, reachedAt: r.reached_at })),
  };
}
