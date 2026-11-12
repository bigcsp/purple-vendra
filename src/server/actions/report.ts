"use server";

import { createClient } from "@/server/db/supabase";
import { REPORT_REASONS } from "@/lib/report-reasons";

export type ReportResult = { ok?: true; error?: string };

/**
 * Sends a report about a listing, a Purple Stories video or a person. The database fills in the
 * seller for listing reports, blocks self-reports and duplicates, limits
 * reports to 10 a day, and hides a listing once 3 established users
 * report it.
 */
export async function submitReport(input: {
  listingId?: string;
  userId?: string;
  videoId?: string;
  requestId?: string;
  reason: string;
  details?: string;
}): Promise<ReportResult> {
  if (!(input.reason in REPORT_REASONS)) return { error: "Choose a reason." };
  if (!input.listingId && !input.userId && !input.videoId && !input.requestId) return { error: "Nothing to report." };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Please sign in to report something." };

  const { error } = await supabase.from("reports").insert({
    reporter_id: user.id,
    listing_id: input.listingId ?? null,
    video_id: input.listingId ? null : (input.videoId ?? null),
    request_id: input.listingId || input.videoId ? null : (input.requestId ?? null),
    // The database fills in the seller for listing and video reports, and
    // keeps request posters anonymous.
    reported_user_id: input.listingId || input.videoId || input.requestId ? null : input.userId,
    reason: input.reason,
    details: input.details?.trim().slice(0, 2000) || null,
  });

  if (error) {
    if (error.code === "23505") return { error: "You've already reported this. We're looking into it." };
    return { error: error.message };
  }
  return { ok: true };
}
