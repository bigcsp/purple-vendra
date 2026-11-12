import Link from "next/link";
import { Suspense } from "react";
import { getNavData } from "@/server/queries/nav";
import { HeaderSearch } from "./header-search";
import { SellerTabs } from "./nav/seller-tabs";
import { ThemeToggle } from "./theme-toggle";
import { Wordmark } from "./wordmark";

/**
 * Top bar on every page: search, theme switch and sign-in.
 * Navigation itself lives in the sidebar (tablet/desktop) and the tab bar
 * (phones); the logo shows here only on phones, where there's no sidebar.
 */
export function SiteHeader() {
  return (
    <header className="sticky top-0 z-30 -mx-5 -mt-8 mb-2 border-b border-border/70 bg-background/90 px-5 backdrop-blur-md">
      <div className="flex flex-wrap items-center gap-3 py-3">
        <Link
          href="/"
          aria-label="Purple Shop home"
          className="flex items-center rounded-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand md:hidden"
        >
          <Wordmark size="sm" />
        </Link>
        <div className="order-last w-full md:order-none md:w-auto md:max-w-xl md:flex-1">
          <Suspense fallback={<div className="h-9 w-full rounded-full border border-border bg-card" />}>
            <HeaderSearch />
          </Suspense>
        </div>
        <div className="ml-auto flex items-center gap-2">
          <Suspense fallback={<span className="h-9 w-20" />}>
            <AuthButtons />
          </Suspense>
          <ThemeToggle />
        </div>
      </div>
      <Suspense fallback={null}>
        <PhoneSellerTabs />
      </Suspense>
    </header>
  );
}

async function AuthButtons() {
  const nav = await getNavData();
  if (nav.signedIn) return null;
  return (
    <nav aria-label="Account" className="flex items-center gap-1 text-sm">
      <Link href="/login" className="hidden rounded-lg px-3 py-2 font-medium text-foreground/80 transition-colors hover:bg-brand-soft/60 hover:text-foreground sm:inline-block">
        Sign in
      </Link>
      <Link href="/signup" className="rounded-lg bg-brand px-4 py-2 font-medium text-white transition-colors hover:bg-brand-deep">
        Join free
      </Link>
    </nav>
  );
}

async function PhoneSellerTabs() {
  const nav = await getNavData();
  if (!nav.isSeller || !nav.username) return null;
  return <SellerTabs username={nav.username} />;
}
