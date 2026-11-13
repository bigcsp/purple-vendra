import "server-only";

import { cache } from "react";
import { connection } from "next/server";
import { createClient } from "@/server/db/supabase";

export type Role = "buyer" | "seller" | "admin";

export type CurrentUser = {
  id: string;
  email: string;
  displayName: string;
  username: string;
  role: Role;
  has2fa: boolean;
  /** true when this session was confirmed with an authenticator code */
  is2faConfirmed: boolean;
  /** "active" unless an admin suspended or banned the account */
  accountStatus: "active" | "suspended" | "banned";
  statusReason: string | null;
  suspendedUntil: string | null;
  /** what they chose at sign-up: shop, sell or both */
  intent: "shop" | "sell" | "both";
  /** set when the person asked to delete their account (30-day grace period) */
  deletionRequestedAt: string | null;
};

/**
 * Reads the signed-in user from the session cookie and loads their profile.
 * Returns null when nobody is signed in. Reads the request, so call it
 * from a component that sits behind <Suspense>.
 */
export const getCurrentUser = cache(async (): Promise<CurrentUser | null> => {
  // Who is signed in must be worked out for each real visit, never
  // pre-rendered ahead of time (Supabase checks the session's expiry
  // time, which Next.js 16 doesn't allow during pre-rendering).
  await connection();

  const supabase = await createClient();

  // getClaims() checks the login token's signature, so it can't be faked by
  // editing the cookie. With Supabase's signing keys it does this on our
  // server, without a round trip to Supabase on every page.
  const { data: claimsData } = await supabase.auth.getClaims();
  const claims = claimsData?.claims;
  if (!claims?.sub) return null;
  const userId = claims.sub;
  const email = typeof claims.email === "string" ? claims.email : "";
  const metadata = (claims.user_metadata ?? {}) as { intent?: string };

  const [{ data: profile }, { data: aal }] = await Promise.all([
    supabase.from("profiles").select("display_name, username, role, account_status, status_reason, suspended_until, deletion_requested_at").eq("id", userId).single(),
    supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
  ]);

  return {
    id: userId,
    email,
    displayName: profile?.display_name ?? (email || "Member"),
    username: profile?.username ?? "",
    role: (profile?.role as Role | undefined) ?? "buyer",
    // Someone with a verified authenticator either used it this session
    // (aal2) or will be asked for it (next level aal2).
    has2fa: aal?.currentLevel === "aal2" || aal?.nextLevel === "aal2",
    is2faConfirmed: aal?.currentLevel === "aal2",
    accountStatus: effectiveStatus(profile?.account_status, profile?.suspended_until),
    statusReason: profile?.status_reason ?? null,
    suspendedUntil: profile?.suspended_until ?? null,
    deletionRequestedAt: profile?.deletion_requested_at ?? null,
    intent: metadata.intent === "sell" || metadata.intent === "both" ? metadata.intent : "shop",
  };
});

/** A suspension with an end date lifts itself once that date has passed. */
function effectiveStatus(status: string | undefined, until: string | null | undefined): CurrentUser["accountStatus"] {
  if (status === "banned") return "banned";
  if (status === "suspended") {
    if (until && new Date(until).getTime() <= Date.now()) return "active";
    return "suspended";
  }
  return "active";
}
