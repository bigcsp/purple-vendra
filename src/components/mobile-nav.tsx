"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { NAV_MOBILE, isActive, type NavItem } from "./nav/nav-config";

/**
 * Phone tab bar (below 768px). Six destinations, outline icons in grey,
 * the current page in brand purple with a soft highlight. Sits above the
 * iPhone home indicator; the page leaves room for it, so it never covers content.
 */
export function MobileNav({ unread = 0, cartCount = 0 }: { unread?: number; cartCount?: number }) {
  const path = usePathname();
  const badgeFor = (item: NavItem) => (item.badge === "unread" ? unread : item.badge === "cart" ? cartCount : 0);

  return (
    <nav
      aria-label="Main menu"
      className="fixed inset-x-0 bottom-0 z-40 border-t border-border/80 bg-card pb-[env(safe-area-inset-bottom)] shadow-[0_-4px_16px_rgba(26,16,36,0.05)] md:hidden"
    >
      <ul className="mx-auto grid h-16 max-w-lg grid-cols-6">
        {NAV_MOBILE.map((item) => {
          const active = isActive(path, item);
          const badge = badgeFor(item);
          const Icon = item.icon;
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={`flex h-full flex-col items-center justify-center gap-1 text-[11px] leading-none transition-colors ${
                  active ? "font-semibold text-brand" : "font-medium text-muted active:text-foreground"
                }`}
              >
                <span className={`relative flex h-8 w-12 items-center justify-center rounded-full transition-colors ${active ? "bg-brand-soft" : ""}`}>
                  <Icon
                    className="h-[22px] w-[22px]"
                    strokeWidth={active ? 2.1 : 1.6}
                    fill={active ? "currentColor" : "none"}
                    fillOpacity={active ? 0.15 : 0}
                    aria-hidden
                  />
                  {badge > 0 && (
                    <span className="absolute right-1 top-0 min-w-4 rounded-full bg-brand px-1 text-center text-[10px] font-semibold leading-4 text-white ring-2 ring-card">
                      {badge > 9 ? "9+" : badge}
                    </span>
                  )}
                </span>
                {item.short ?? item.label}
                {badge > 0 && <span className="sr-only">, {badge} new</span>}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
