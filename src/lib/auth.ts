import "server-only";

import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";

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
};

/**
 * Reads the signed-in user from the session cookie and loads their profile.
 * Returns null when nobody is signed in. Reads the request, so call it
 * from a component that sits behind <Suspense>.
 */
export async function getCurrentUser(): Promise<CurrentUser | null> {
  // Who is signed in must be worked out for each real visit, never
  // pre-rendered ahead of time (Supabase checks the session's expiry
  // time, which Next.js 16 doesn't allow during pre-rendering).
  await connection();

  const supabase = await createClient();

  // getUser() checks the token with Supabase, so it can't be faked by
  // editing the cookie.
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: profile }, { data: aal }] = await Promise.all([
    supabase.from("profiles").select("display_name, username, role").eq("id", user.id).single(),
    supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
  ]);

  return {
    id: user.id,
    email: user.email ?? "",
    displayName: profile?.display_name ?? user.email ?? "Member",
    username: profile?.username ?? "",
    role: (profile?.role as Role | undefined) ?? "buyer",
    has2fa: (user.factors ?? []).some((f) => f.status === "verified"),
    is2faConfirmed: aal?.currentLevel === "aal2",
  };
}
