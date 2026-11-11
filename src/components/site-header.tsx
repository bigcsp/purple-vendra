import Link from "next/link";
import { Suspense } from "react";
import { getCurrentUser } from "@/lib/auth";
import { LogoMark } from "./adire";
import { HeaderNav } from "./header-nav";
import { ThemeToggle } from "./theme-toggle";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-30 -mx-5 -mt-8 mb-2 flex flex-wrap items-center justify-between gap-3 border-b border-border/70 bg-background/85 px-5 py-3 backdrop-blur-md">
      <Link href="/" className="flex items-center gap-2 font-display text-lg font-bold tracking-tight text-brand-strong sm:text-xl">
        <LogoMark className="h-8 w-8" />
        <span>Purple Vendra</span>
      </Link>
      <form action="/search" role="search" className="order-last w-full sm:order-none sm:w-auto sm:max-w-xs sm:flex-1">
        <label className="relative block">
          <span className="sr-only">Search Purple Vendra</span>
          <svg viewBox="0 0 24 24" className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-3.5-3.5" />
          </svg>
          <input
            type="search"
            name="q"
            placeholder="Search adire, logo design, plumber…"
            className="w-full rounded-full border border-border bg-card py-2 pl-10 pr-4 text-sm outline-none transition focus:border-brand focus:ring-2 focus:ring-brand-soft"
          />
        </label>
      </form>
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

  return <HeaderNav username={user.username} isSeller={user.role !== "buyer"} />;
}
