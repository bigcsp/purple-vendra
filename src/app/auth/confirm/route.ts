import type { EmailOtpType } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/server/db/supabase";
import { safeNext } from "@/lib/safe-next";

/**
 * The link in the "confirm your email" message lands here.
 * Handles both link styles Supabase can send:
 *   /auth/confirm?token_hash=...&type=email   (recommended email template)
 *   /auth/confirm?code=...                    (default template)
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const next = safeNext(searchParams.get("next"));
  const tokenHash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;
  const code = searchParams.get("code");

  const supabase = await createClient();

  if (tokenHash && type) {
    const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type });
    if (!error) return NextResponse.redirect(new URL(next, origin));
    return NextResponse.redirect(new URL(`/login?error=link&next=${encodeURIComponent(next)}`, origin));
  }

  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(new URL(next, origin));
    // With the default email, Supabase has already confirmed the address before
    // sending the person here. Signing them in only works in the same browser
    // they signed up in, so a link opened on another phone, or inside the Gmail
    // app, lands here. Their email IS confirmed: ask them to sign in.
    return NextResponse.redirect(new URL(`/login?confirmed=1&next=${encodeURIComponent(next)}`, origin));
  }

  return NextResponse.redirect(new URL("/login?error=link", origin));
}
