"use server";

import { revalidatePath } from "next/cache";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { nairaToKobo } from "@/lib/money";
import { createClient } from "@/lib/supabase/server";

export type CampaignInput = {
  videoId: string;
  categoryIds: number[];
  states: string[];
  audienceNote: string;
  durationDays: number;
  budget: string;
};

export async function createCampaign(input: CampaignInput): Promise<{ ok?: true; error?: string }> {
  const budget = nairaToKobo(input.budget);
  if (budget === null || budget < 100000) return { error: "Minimum budget is ₦1,000." };
  if (budget > 100000000) return { error: "Maximum budget is ₦1,000,000 per campaign." };
  if (!Number.isInteger(input.durationDays) || input.durationDays < 1 || input.durationDays > 30)
    return { error: "Choose 1–30 days." };
  const states = input.states.filter((s) => (NIGERIAN_STATES as readonly string[]).includes(s));

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Please sign in again." };

  // The database forces "awaiting payment" and checks the story is yours and published.
  const { error } = await supabase.from("story_campaigns").insert({
    seller_id: user.id,
    video_id: input.videoId,
    audience_categories: input.categoryIds.filter(Number.isInteger),
    audience_states: states,
    audience_note: input.audienceNote.trim().slice(0, 300) || null,
    duration_days: input.durationDays,
    budget_kobo: budget,
  });
  if (error) return { error: /2FA|row-level/i.test(error.message) ? "Not allowed. Sign in with your 2FA code." : error.message };
  revalidatePath("/sell/stories/promote");
  return { ok: true };
}

export async function setCampaignStatus(id: string, status: "cancelled" | "paused" | "active"): Promise<{ ok?: true; error?: string }> {
  const supabase = await createClient();
  const { error, count } = await supabase.from("story_campaigns").update({ status }, { count: "exact" }).eq("id", id);
  if (error) return { error: error.message };
  if (!count) return { error: "Campaign not found." };
  revalidatePath("/sell/stories/promote");
  return { ok: true };
}
