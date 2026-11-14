import {
  BriefcaseBusiness,
  CirclePlay,
  CircleUser,
  Clapperboard,
  ClipboardList,
  Heart,
  House,
  LayoutDashboard,
  MessageCircle,
  Package,
  Receipt,
  ShieldCheck,
  ShoppingBag,
  Store,
  type LucideIcon,
} from "lucide-react";

/**
 * The single source of truth for Purple Shop navigation. The desktop
 * sidebar, the tablet rail and the phone tab bar all read from here, so
 * they can never disagree about where things are.
 */
export type NavItem = {
  href: string;
  label: string;
  /** Shorter label for the phone tab bar. */
  short?: string;
  icon: LucideIcon;
  /** Only highlight on an exact match (for "/" and "/sell"). */
  exact?: boolean;
  badge?: "unread" | "cart";
};

export const NAV_MAIN: NavItem[] = [
  { href: "/", label: "Home", icon: House, exact: true },
  { href: "/requests", label: "Requests", icon: ClipboardList },
  { href: "/stories", label: "Stories", icon: CirclePlay },
  { href: "/messages", label: "Chats", icon: MessageCircle, badge: "unread" },
  { href: "/cart", label: "Cart", icon: ShoppingBag, badge: "cart" },
  { href: "/saved", label: "Saved", icon: Heart },
];

export const NAV_ACCOUNT: NavItem = { href: "/account", label: "My account", short: "Me", icon: CircleUser };

/** Phone tab bar: six thumb-sized destinations. */
export const NAV_MOBILE: NavItem[] = [
  NAV_MAIN[0],
  NAV_MAIN[1],
  NAV_MAIN[2],
  NAV_MAIN[3],
  NAV_MAIN[4],
  NAV_ACCOUNT,
];

/** Seller tools: shown as a group in the sidebar, and as tabs on phones inside /sell. */
export function sellerNav(username: string): NavItem[] {
  return [
    { href: "/sell", label: "Seller hub", short: "Hub", icon: LayoutDashboard, exact: true },
    { href: `/shop/${username}`, label: "My shop", short: "Shop", icon: Store },
    { href: "/sell/pro", label: "Professional page", short: "Pro page", icon: BriefcaseBusiness },
    { href: "/sell/listings", label: "Listings", icon: Package },
    { href: "/sell/stories", label: "My stories", short: "Stories", icon: Clapperboard },
    { href: "/sell/orders", label: "Orders", icon: Receipt },
  ];
}

export const NAV_SAFETY: NavItem = { href: "/safety", label: "Safety & escrow", icon: ShieldCheck };

export function isActive(path: string, item: NavItem): boolean {
  if (item.exact) return path === item.href;
  return path === item.href || path.startsWith(`${item.href}/`);
}

export type NavData = {
  signedIn: boolean;
  isSeller: boolean;
  username: string | null;
  displayName: string | null;
  unread: number;
  cartCount: number;
};

export const GUEST_NAV: NavData = { signedIn: false, isSeller: false, username: null, displayName: null, unread: 0, cartCount: 0 };
