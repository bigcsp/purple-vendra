import "server-only";

import { NextResponse } from "next/server";
import { connection } from "next/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";
import { createPublicClient } from "@/server/db/supabase";

const DB_TIMEOUT_MS = 3000;

/**
 * GET /api/health → is the site up, and can it reach the database?
 * For uptime monitors. 200 when everything works, 503 when the database
 * can't be reached in 3 seconds. Shows no data and no error details.
 */
export async function GET() {
  // Answer every check live, never from a cached copy.
  await connection();
  const started = Date.now();

  let database: "ok" | "down" | "not_configured" = "not_configured";
  if (isSupabaseConfigured) {
    try {
      const query = createPublicClient().from("categories").select("id").limit(1);
      const timeout = new Promise<{ error: Error }>((resolve) =>
        setTimeout(() => resolve({ error: new Error("timeout") }), DB_TIMEOUT_MS),
      );
      const { error } = await Promise.race([query, timeout]);
      database = error ? "down" : "ok";
    } catch {
      database = "down";
    }
  }

  const ok = database === "ok";
  return NextResponse.json(
    {
      status: ok ? "ok" : "degraded",
      database,
      responseMs: Date.now() - started,
      region: process.env.VERCEL_REGION ?? "local",
      checkedAt: new Date().toISOString(),
    },
    { status: ok ? 200 : 503, headers: { "Cache-Control": "no-store" } },
  );
}
