import Link from "next/link";
import { Suspense } from "react";
import { getCurrentUser } from "@/lib/auth";
import { HeaderNav } from "./header-nav";

export function SiteHeader() {
  return (
    <header className="flex flex-wrap items-center justify-between gap-3">
      <Link href="/" className="text-xl font-bold text-brand">
        Purple Vendra
      </Link>
      <Suspense fallback={<span className="h-8 w-20" />}>
        <UserMenu />
      </Suspense>
    </header>
  );
}

async function UserMenu() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <nav className="flex items-center gap-2 text-sm">
        <Link href="/stories" className="rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft">
          Stories
        </Link>
        <Link href="/login" className="rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft">
          Sign in
        </Link>
        <Link href="/signup" className="rounded-full bg-brand px-4 py-1.5 font-medium text-white hover:bg-brand-strong">
          Join
        </Link>
      </nav>
    );
  }

  return <HeaderNav username={user.username} isSeller={user.role !== "buyer"} />;
}
