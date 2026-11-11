import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * Downloads everything Purple Vendra holds about the signed-in person as a
 * JSON file (NDPA right of access). Limited to 5 downloads a day and logged
 * by the database.
 */
export async function GET(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.redirect(new URL("/login?next=/account/privacy", request.url));

  const { data, error } = await supabase.rpc("export_my_data");
  if (error) {
    return new NextResponse(error.message, { status: error.code === "54000" ? 429 : 400, headers: { "Content-Type": "text/plain; charset=utf-8" } });
  }

  const date = new Date().toISOString().slice(0, 10);
  return new NextResponse(JSON.stringify(data, null, 2), {
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Content-Disposition": `attachment; filename="purple-vendra-my-data-${date}.json"`,
      "Cache-Control": "no-store",
    },
  });
}
