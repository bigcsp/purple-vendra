import "server-only";

import { cache } from "react";
import type { NavData } from "@/components/nav/nav-config";
import { getCurrentUser } from "@/server/auth/session";
import { createClient } from "@/server/db/supabase";
import { getUnreadCount } from "@/server/queries/messages";

/** Everything the navigation needs: who's signed in, unread chats, cart size (once per request). */
export const getNavData = cache(async function getNavData(): Promise<NavData> {
  const user = await getCurrentUser();
  if (!user) {
    return { signedIn: false, isSeller: false, username: null, displayName: null, unread: 0, cartCount: 0 };
  }
  const supabase = await createClient();
  const [unread, cart] = await Promise.all([
    getUnreadCount(),
    supabase.from("cart_items").select("quantity").eq("user_id", user.id),
  ]);
  const cartCount = (cart.data ?? []).reduce((n, r) => n + (Number(r.quantity) || 0), 0);
  return {
    signedIn: true,
    isSeller: user.role !== "buyer",
    username: user.username,
    displayName: user.displayName,
    unread,
    cartCount,
  };
});
