import "server-only";

import { createClient } from "@/server/db/supabase";
import type { IdType } from "@/lib/id-types";

export type Verification = {
  status: "none" | "pending" | "approved" | "rejected";
  idType: IdType | null;
  rejectionReason: string | null;
  submittedAt: string | null;
};

/** The signed-in seller's ID verification (RLS only returns their own row). */
export async function getMyVerification(userId: string): Promise<Verification> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("seller_verifications")
    .select("status, id_type, rejection_reason, submitted_at")
    .eq("user_id", userId)
    .maybeSingle();

  if (!data) return { status: "none", idType: null, rejectionReason: null, submittedAt: null };
  return {
    status: data.status,
    idType: data.id_type,
    rejectionReason: data.rejection_reason,
    submittedAt: data.submitted_at,
  };
}

export const verificationLabel: Record<Verification["status"], { text: string; tone: string }> = {
  none: { text: "Not verified yet", tone: "bg-brand-soft text-brand" },
  pending: { text: "Under review", tone: "bg-amber-100 text-amber-800" },
  approved: { text: "Verified ✓", tone: "bg-green-100 text-green-800" },
  rejected: { text: "Needs a new upload", tone: "bg-red-100 text-red-700" },
};
