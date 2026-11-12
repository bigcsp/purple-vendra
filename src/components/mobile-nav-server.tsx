import { getCurrentUser } from "@/lib/auth";
import { getUnreadCount } from "@/lib/messages";
import { MobileNav } from "./mobile-nav";

/** Loads the unread chat count for the phone menu. */
export async function MobileNavWithCounts() {
  const user = await getCurrentUser();
  const unread = user ? await getUnreadCount() : 0;
  return <MobileNav unread={unread} />;
}
