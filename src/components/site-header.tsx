import Link from "next/link";
import { Suspense } from "react";
import { getCurrentUser } from "@/lib/auth";
import { getUnreadCount } from "@/lib/messages";
import { HeaderNav } from "./header-nav";
import { ThemeToggle } from "./theme-toggle";
import { Wordmark } from "./wordmark";
import { HeaderSearch } from "./header-search";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-30 -mx-5 -mt-8 mb-2 flex flex-wrap items-center justify-between gap-3 border-b border-border/70 bg-background/85 px-5 py-3 backdrop-blur-md">
      <Link href="/" aria-label="Purple Shop home" className="flex items-center rounded-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand">
        <Wordmark />
      </Link>
      <div className="order-last w-full sm:order-none sm:w-auto sm:max-w-sm sm:flex-1">
        <Suspense fallback={<div className="h-9 w-full rounded-full border border-border bg-card" />}>
          <HeaderSearch />
        </Suspense>
      </div>
      <div className="flex items-center gap-2">
        <Suspense fallback={<span className="h-8 w-20" />}>
          <UserMenu />
        </Suspense>
        <ThemeToggle />
      </div>
    </header>
  );
}

async function UserMenu() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <nav className="flex items-center gap-1 text-sm sm:gap-2">
        <Link href="/requests" className="hidden rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft sm:inline-block">
          Requests
        </Link>
        <Link href="/stories" className="hidden rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft sm:inline-block">
          Stories
        </Link>
        <Link href="/login" className="hidden rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft sm:inline-block">
          Sign in
        </Link>
        <Link href="/signup" className="rounded-full bg-brand px-4 py-1.5 font-medium text-white hover:bg-brand-deep">
          Join free
        </Link>
      </nav>
    );
  }

  const unread = await getUnreadCount();
  return <HeaderNav username={user.username} isSeller={user.role !== "buyer"} unread={unread} />;
}
