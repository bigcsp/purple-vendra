"use client";

import Link from "next/link";
import { useEffect } from "react";

/**
 * Shown when a page fails to load (for example the database is briefly
 * unreachable). Keeps the visitor on Purple Shop with a way to retry.
 */
export default function PageError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <Link href="/" className="font-display text-xl font-extrabold text-brand">Purple Shop</Link>
      <div className="mx-auto mt-16 max-w-md text-center">
        <h1 className="text-2xl font-bold text-brand-strong">Something went wrong loading this page</h1>
        <p className="mt-2 text-muted">
          It&apos;s usually a short hiccup. Nothing you entered was lost. Try again in a moment.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button onClick={reset} className="rounded-full bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">
            Try again
          </button>
          <Link href="/" className="rounded-full border border-border px-5 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            Home page
          </Link>
        </div>
        {error.digest && <p className="mt-6 text-xs text-muted">Error code: {error.digest}</p>}
      </div>
    </main>
  );
}
