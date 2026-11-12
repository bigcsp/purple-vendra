import Link from "next/link";
import { SiteHeader } from "@/components/site-header";

/** Shown for any page, shop or listing that doesn't exist (or was removed). */
export default function NotFound() {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <div className="mx-auto mt-16 max-w-md text-center">
        <p className="font-display text-6xl font-extrabold text-brand">404</p>
        <h1 className="mt-3 text-2xl font-bold text-brand-strong">We couldn&apos;t find that page</h1>
        <p className="mt-2 text-muted">
          The shop, listing or story may have been removed, or the link has a typo.
        </p>
        <form action="/search" role="search" className="mt-6 flex gap-2">
          <label htmlFor="nf-q" className="sr-only">Search Purple Shop</label>
          <input id="nf-q" name="q" type="search" placeholder="Search Purple Shop"
            className="min-w-0 flex-1 rounded-full border border-border bg-card px-4 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft" />
          <button className="rounded-full bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">Search</button>
        </form>
        <Link href="/" className="mt-4 inline-block text-sm font-medium text-brand underline">Go to the home page</Link>
      </div>
    </main>
  );
}
