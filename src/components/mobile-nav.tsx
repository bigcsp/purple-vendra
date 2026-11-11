"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

type Tab = { href: string; label: string; icon: string; exact?: boolean };

const SHOPPING: Tab[] = [
  { href: "/", label: "Home", icon: "🏠", exact: true },
  { href: "/search", label: "Search", icon: "🔎" },
  { href: "/stories", label: "Stories", icon: "🎬" },
  { href: "/cart", label: "Cart", icon: "🛒" },
  { href: "/account", label: "Me", icon: "👤" },
];

const SELLING: Tab[] = [
  { href: "/sell", label: "Hub", icon: "🏪", exact: true },
  { href: "/sell/listings", label: "Listings", icon: "📦" },
  { href: "/sell/stories", label: "Stories", icon: "🎬" },
  { href: "/sell/orders", label: "Orders", icon: "🧾" },
  { href: "/", label: "Browse", icon: "🛍️", exact: true },
];

/** Thumb-friendly bottom menu on phones (hidden on wider screens). */
export function MobileNav() {
  const path = usePathname();
  const tabs = path === "/sell" || path.startsWith("/sell/") ? SELLING : SHOPPING;
  const active = (t: Tab) => (t.exact ? path === t.href : path === t.href || path.startsWith(`${t.href}/`));

  return (
    <nav
      aria-label="Main menu"
      className="fixed inset-x-0 bottom-0 z-40 border-t border-border bg-card/95 pb-[env(safe-area-inset-bottom)] backdrop-blur sm:hidden"
    >
      <ul className="grid grid-cols-5">
        {tabs.map((t) => (
          <li key={t.href + t.label}>
            <Link
              href={t.href}
              aria-current={active(t) ? "page" : undefined}
              className={`flex flex-col items-center gap-0.5 py-2 text-[11px] font-medium ${active(t) ? "text-brand" : "text-muted"}`}
            >
              <span className={`text-lg leading-none ${active(t) ? "" : "grayscale"}`} aria-hidden>{t.icon}</span>
              {t.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
