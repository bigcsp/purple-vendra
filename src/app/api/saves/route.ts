import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/** GET /api/saves → which listings the signed-in person has saved (for the hearts). */
export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ signedIn: false, ids: [] }, { headers: { "Cache-Control": "no-store" } });
  const { data } = await supabase.from("saves").select("listing_id").eq("user_id", user.id).limit(500);
  return NextResponse.json(
    { signedIn: true, ids: (data ?? []).map((r) => r.listing_id as string) },
    { headers: { "Cache-Control": "private, no-store" } },
  );
}
