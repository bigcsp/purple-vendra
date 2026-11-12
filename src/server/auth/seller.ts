import "server-only";

import { redirect } from "next/navigation";
import { getCurrentUser } from "@/server/auth/session";

/** Same checks as the seller hub: signed in, seller, active, 2FA-confirmed. */
export async function requireSeller(next: string) {
  const user = await getCurrentUser();
  if (!user) redirect(`/login?next=${encodeURIComponent(next)}`);
  if (user.role === "buyer") redirect("/account");
  if (user.accountStatus !== "active") redirect("/account");
  if (!user.is2faConfirmed) redirect(`/account/security?next=${encodeURIComponent(next)}`);
  return user;
}
