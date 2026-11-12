import { getNavData } from "@/server/queries/nav";
import { MobileNav } from "./mobile-nav";
import { Sidebar } from "./nav/sidebar";

/** Loads unread chats and cart size for the phone tab bar. */
export async function MobileNavWithCounts() {
  const data = await getNavData();
  return <MobileNav unread={data.unread} cartCount={data.cartCount} />;
}

/** Loads who's signed in (and their counts) for the desktop sidebar. */
export async function SidebarWithData() {
  const data = await getNavData();
  return <Sidebar data={data} />;
}
