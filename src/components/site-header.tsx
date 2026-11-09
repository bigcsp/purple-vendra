import Link from "next/link";
import { Suspense } from "react";
import { getCurrentUser } from "@/lib/auth";

export function SiteHeader() {
  return (
    <header className="flex items-center justify-between">
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
        <Link href="/login" className="rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft">
          Sign in
        </Link>
        <Link href="/signup" className="rounded-full bg-brand px-4 py-1.5 font-medium text-white hover:bg-brand-strong">
          Join
        </Link>
      </nav>
    );
  }

  return (
    <nav className="flex items-center gap-2 text-sm">
      {user.role !== "buyer" && (
        <Link href="/sell" className="rounded-full px-3 py-1.5 font-medium text-brand hover:bg-brand-soft">
          Seller hub
        </Link>
      )}
      <Link href="/account" className="rounded-full bg-brand-soft px-4 py-1.5 font-medium text-brand">
        @{user.username}
      </Link>
    </nav>
  );
}
