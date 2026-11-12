"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { isActive, sellerNav } from "./nav-config";

/**
 * Seller tools on phones. Inside the seller area (/sell…) a scrollable tab
 * row sits under the top bar, so every seller page stays one tap away
 * without crowding the main tab bar. Tablets and desktops use the sidebar.
 */
export function SellerTabs({ username }: { username: string }) {
  const path = usePathname();
  if (!(path === "/sell" || path.startsWith("/sell/"))) return null;
  const items = sellerNav(username);

  return (
    <nav aria-label="Seller tools" className="-mx-5 overflow-x-auto border-t border-border/70 md:hidden">
      <ul className="flex min-w-max gap-1 px-4 py-2">
        {items.map((item) => {
          const active = isActive(path, item);
          const Icon = item.icon;
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm transition-colors ${
                  active ? "bg-brand-soft font-semibold text-brand" : "font-medium text-muted hover:text-foreground"
                }`}
              >
                <Icon className="h-4 w-4" strokeWidth={active ? 2.1 : 1.75} aria-hidden />
                {item.short ?? item.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
