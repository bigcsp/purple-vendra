"use client";

import { LogIn, PanelLeftClose, PanelLeftOpen, Store, type LucideIcon } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useSyncExternalStore } from "react";
import { Wordmark } from "@/components/wordmark";
import { NAV_ACCOUNT, NAV_MAIN, NAV_SAFETY, isActive, sellerNav, type NavData, type NavItem } from "./nav-config";

/**
 * Desktop and tablet navigation.
 *  - 768–1023px: a slim icon rail (labels appear as tooltips).
 *  - 1024px and up: a full sidebar with labels, which can be collapsed to
 *    the rail. The choice is remembered on this device and applied before
 *    the page paints (see sidebarScript), so it never jumps.
 * Phones use the bottom tab bar instead; the two never show together.
 */
const KEY = "ps-sidebar";

function collapsedNow() {
  return document.documentElement.dataset.sidebar === "collapsed";
}
function subscribe(cb: () => void) {
  const obs = new MutationObserver(cb);
  obs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-sidebar"] });
  return () => obs.disconnect();
}

export function Sidebar({ data }: { data: NavData }) {
  const path = usePathname();
  const collapsed = useSyncExternalStore(subscribe, collapsedNow, () => false);

  const toggle = () => {
    const next = collapsedNow() ? "expanded" : "collapsed";
    document.documentElement.dataset.sidebar = next;
    try {
      localStorage.setItem(KEY, next);
    } catch {
      /* private mode */
    }
  };

  const badgeFor = (item: NavItem) =>
    item.badge === "unread" ? data.unread : item.badge === "cart" ? data.cartCount : 0;

  return (
    <aside
      aria-label="Main navigation"
      className="ps-sidebar fixed inset-y-0 left-0 z-40 hidden flex-col border-r border-border bg-card md:flex"
    >
      {/* Brand */}
      <div className="flex h-16 shrink-0 items-center px-4">
        <Link href="/" aria-label="Purple Shop home" className="ps-full rounded-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand">
          <Wordmark size="sm" />
        </Link>
        <Link href="/" aria-label="Purple Shop home" className="ps-rail-only mx-auto block rounded-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/icon.svg" alt="" className="h-9 w-9 rounded-[10px]" />
        </Link>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 pb-3">
        <Group>
          {NAV_MAIN.map((item) => (
            <SideLink key={item.href} item={item} active={isActive(path, item)} badge={badgeFor(item)} />
          ))}
        </Group>

        {data.isSeller && data.username ? (
          <Group title="Selling">
            {sellerNav(data.username).map((item) => (
              <SideLink key={item.href} item={item} active={isActive(path, item)} />
            ))}
          </Group>
        ) : (
          <Group title="Selling">
            <SideLink
              item={{ href: data.signedIn ? "/welcome" : "/signup?intent=sell", label: "Start selling", icon: Store }}
              active={path === "/welcome"}
            />
          </Group>
        )}
      </nav>

      <div className="shrink-0 border-t border-border px-3 py-3">
        <SideLink item={NAV_SAFETY} active={isActive(path, NAV_SAFETY)} />
        {data.signedIn ? (
          <SideLink
            item={NAV_ACCOUNT}
            active={isActive(path, NAV_ACCOUNT)}
            sub={data.username ? `@${data.username}` : undefined}
          />
        ) : (
          <SideLink item={{ href: "/login", label: "Sign in", icon: LogIn }} active={path === "/login"} />
        )}
        <button
          type="button"
          onClick={toggle}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          aria-expanded={!collapsed}
          className="ps-lg-only group mt-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted transition-colors hover:bg-brand-soft/60 hover:text-foreground"
        >
          {collapsed ? (
            <PanelLeftOpen className="h-[18px] w-[18px] shrink-0" strokeWidth={1.75} aria-hidden />
          ) : (
            <PanelLeftClose className="h-[18px] w-[18px] shrink-0" strokeWidth={1.75} aria-hidden />
          )}
          <span className="ps-full">Collapse</span>
        </button>
      </div>
    </aside>
  );
}

function Group({ title, children }: { title?: string; children: React.ReactNode }) {
  return (
    <div className="mt-2 first:mt-0">
      {title && (
        <>
          <p className="ps-full px-3 pb-1 pt-4 text-xs font-medium text-muted">{title}</p>
          <div className="ps-rail-only mx-3 my-3 border-t border-border" aria-hidden />
        </>
      )}
      <ul className="space-y-0.5">{children}</ul>
    </div>
  );
}

function SideLink({ item, active, badge = 0, sub }: { item: NavItem; active: boolean; badge?: number; sub?: string }) {
  const Icon: LucideIcon = item.icon;
  return (
    <li className="list-none">
      <Link
        href={item.href}
        aria-current={active ? "page" : undefined}
        title={item.label}
        className={`group relative flex items-center gap-3 rounded-lg px-3 py-2 text-[0.9375rem] transition-colors duration-150 ${
          active ? "bg-brand-soft font-medium text-brand" : "text-foreground/80 hover:bg-brand-soft/60 hover:text-foreground"
        }`}
      >
        {active && <span className="absolute inset-y-1.5 -left-3 w-[3px] rounded-r-full bg-brand" aria-hidden />}
        <span className="relative shrink-0">
          <Icon
            className="h-5 w-5 transition-transform duration-150 group-hover:scale-105"
            strokeWidth={active ? 2.1 : 1.75}
            fill={active ? "currentColor" : "none"}
            fillOpacity={active ? 0.12 : 0}
            aria-hidden
          />
          {badge > 0 && (
            <span className="ps-rail-only absolute -right-1.5 -top-1.5 h-2.5 w-2.5 rounded-full bg-accent ring-2 ring-card" aria-hidden />
          )}
        </span>
        <span className="ps-full min-w-0 flex-1 truncate">
          {item.label}
          {sub && <span className="block truncate text-xs font-normal text-muted">{sub}</span>}
        </span>
        {badge > 0 && (
          <span className="ps-full ml-auto min-w-5 rounded-full bg-brand px-1.5 text-center text-[11px] font-semibold leading-5 text-white">
            {badge > 99 ? "99+" : badge}
          </span>
        )}
        {badge > 0 && <span className="sr-only">({badge})</span>}
      </Link>
    </li>
  );
}
