"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

type Item = { href: string; label: string; exact?: boolean };

/**
 * Signed-in navigation. Inside the seller area (/sell/...) sellers see their
 * business links; everywhere else everyone sees the shopping links.
 */
export function HeaderNav({ username, isSeller, unread = 0 }: { username: string; isSeller: boolean; unread?: number }) {
  const path = usePathname();
  const inSellerArea = isSeller && (path === "/sell" || path.startsWith("/sell/"));

  const items: Item[] = inSellerArea
    ? [
        { href: "/sell", label: "Seller hub", exact: true },
        { href: `/shop/${username}`, label: "My shop" },
        { href: "/sell/listings", label: "Listings" },
        { href: "/sell/stories", label: "Stories" },
        { href: "/sell/orders", label: "Orders" },
        { href: "/messages", label: "Messages" },
      ]
    : [
        { href: "/stories", label: "Stories" },
        { href: "/saved", label: "Saved" },
        { href: "/messages", label: "Messages" },
        { href: "/cart", label: "Cart" },
        ...(isSeller ? [{ href: "/sell", label: "Seller hub" }] : []),
      ];

  const isActive = (i: Item) => (i.exact ? path === i.href : path === i.href || path.startsWith(`${i.href}/`));

  return (
    <nav className="-mx-1 flex max-w-full items-center gap-1 overflow-x-auto px-1 text-sm sm:gap-2">
      {items.map((i) => (
        <Link
          // On phones the bottom menu has these links, so keep the header short.
          key={i.href}
          href={i.href}
          aria-current={isActive(i) ? "page" : undefined}
          className={`hidden shrink-0 rounded-full px-3 py-1.5 font-medium sm:inline-block ${
            isActive(i) ? "bg-brand text-white" : "text-brand hover:bg-brand-soft"
          }`}
        >
          {i.label}
          {i.href === "/messages" && unread > 0 && (
            <span className="ml-1.5 inline-flex min-w-5 items-center justify-center rounded-full bg-accent px-1.5 text-xs font-bold text-brand-strong">
              {unread > 99 ? "99+" : unread}
              <span className="sr-only"> unread</span>
            </span>
          )}
        </Link>
      ))}
      <Link href="/account" className="shrink-0 rounded-full bg-brand-soft px-4 py-1.5 font-medium text-brand">
        @{username}
      </Link>
    </nav>
  );
}
