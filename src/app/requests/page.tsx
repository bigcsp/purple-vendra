import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { RequestCard } from "@/components/requests/request-card";
import { getCurrentUser } from "@/server/auth/session";
import { getCategories } from "@/server/queries/catalog";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { BOARD_PAGE_SIZE, getBoard } from "@/server/queries/requests";

export const metadata: Metadata = {
  title: "Purple Requests · Purple Shop",
  description: "Tell Nigerian makers, freelancers and pros what you need, and get offers. Pay safely through escrow.",
};

export default function RequestsPage({ searchParams }: PageProps<"/requests">) {
  return (
    <PageShell wide>
      <section className="rounded-[2rem] bg-panel px-6 py-8 text-white sm:px-10">
        <h1 className="text-3xl font-bold sm:text-4xl">Purple Requests</h1>
        <p className="mt-2 max-w-xl text-white/85">
          Can&apos;t find it? Say what you need, set your budget, and let sellers send you offers. Compare them, chat, then
          pay safely through Purple Shop escrow.
        </p>
        <div className="mt-5 flex flex-wrap gap-3">
          <Link href="/requests/new" className="rounded-full bg-accent px-5 py-2.5 font-semibold text-brand-strong hover:brightness-105">
            Post a request
          </Link>
          <Link href="/requests/mine" className="rounded-full bg-white/15 px-5 py-2.5 font-medium text-white hover:bg-white/25">
            My requests &amp; offers
          </Link>
        </div>
      </section>

      <Suspense fallback={<p className="mt-8 text-sm text-muted">Loading requests…</p>}>
        <Board searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

async function Board({ searchParams }: { searchParams: PageProps<"/requests">["searchParams"] }) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (typeof v === "string" ? v : "");
  const q = one(sp.q).trim().slice(0, 100);
  const cat = one(sp.category);
  const state = NIGERIAN_STATES.includes(one(sp.state) as (typeof NIGERIAN_STATES)[number]) ? one(sp.state) : "";
  const page = Math.max(1, Number.parseInt(one(sp.page), 10) || 1);

  const [categories, user] = await Promise.all([getCategories(), getCurrentUser()]);
  const isSeller = !!user && user.role !== "buyer";
  const matches = isSeller && one(sp.view) === "matches";
  const category = categories.find((c) => c.slug === cat) ?? null;
  const { requests, total } = await getBoard({ q, categoryId: category?.id ?? null, state: state || null, matches, page });
  const names = new Map(categories.map((c) => [c.id, c.name]));
  const pages = Math.max(1, Math.ceil(total / BOARD_PAGE_SIZE));

  const link = (over: Record<string, string>) => {
    const p = new URLSearchParams({ ...(q && { q }), ...(cat && { category: cat }), ...(state && { state }), ...(matches && { view: "matches" }), ...over });
    for (const [k, v] of [...p]) if (!v) p.delete(k);
    const s = p.toString();
    return `/requests${s ? `?${s}` : ""}`;
  };

  return (
    <div className="mt-8 space-y-5">
      {isSeller && (
        <div className="flex rounded-full border border-border bg-card p-1 text-sm sm:w-fit">
          <Link href={link({ view: "", page: "" })} aria-current={!matches ? "page" : undefined}
            className={`flex-1 rounded-full px-4 py-1.5 text-center font-medium ${!matches ? "bg-brand text-white" : "text-brand"}`}>
            All requests
          </Link>
          <Link href={link({ view: "matches", page: "" })} aria-current={matches ? "page" : undefined}
            className={`flex-1 rounded-full px-4 py-1.5 text-center font-medium ${matches ? "bg-brand text-white" : "text-brand"}`}>
            Matches for you
          </Link>
        </div>
      )}

      <form action="/requests" className="grid gap-2 sm:grid-cols-[1fr_auto_auto_auto]">
        {matches && <input type="hidden" name="view" value="matches" />}
        <label className="sr-only" htmlFor="rq">Search requests</label>
        <input id="rq" name="q" defaultValue={q} placeholder="Search requests, e.g. aso ebi, logo, plumber"
          className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft" />
        <label className="sr-only" htmlFor="rc">Category</label>
        <select id="rc" name="category" defaultValue={cat} className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm">
          <option value="">All categories</option>
          {categories.map((c) => <option key={c.id} value={c.slug}>{c.name}</option>)}
        </select>
        <label className="sr-only" htmlFor="rs">State</label>
        <select id="rs" name="state" defaultValue={state} className="rounded-xl border border-border bg-card px-3 py-2.5 text-sm">
          <option value="">All of Nigeria</option>
          {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <button className="rounded-xl bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">Search</button>
      </form>

      <p className="text-sm text-muted">
        {total === 0 ? "No open requests match." : `${total} open request${total === 1 ? "" : "s"}`}
        {matches && " in your categories and areas"}
      </p>

      {requests.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-border bg-card p-8 text-center text-sm text-muted">
          {matches ? (
            <p>No requests match your listings and service areas yet. Check &quot;All requests&quot;, or add more listings and service areas.</p>
          ) : (
            <>
              <p>No one has asked for this yet. Post a request and sellers on Purple Shop can send you offers.</p>
              <Link href="/requests/new" className="mt-4 inline-block rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-deep">
                Post a request
              </Link>
            </>
          )}
        </div>
      ) : (
        <ul className="grid gap-4 md:grid-cols-2">
          {requests.map((r) => <RequestCard key={r.id} r={r} categoryName={names.get(r.category_id)} />)}
        </ul>
      )}

      {pages > 1 && (
        <nav aria-label="Pages" className="flex items-center justify-center gap-3 text-sm">
          {page > 1 && <Link href={link({ page: String(page - 1) })} className="rounded-full border border-border px-4 py-2 text-brand hover:bg-brand-soft">← Newer</Link>}
          <span className="text-muted">Page {page} of {pages}</span>
          {page < pages && <Link href={link({ page: String(page + 1) })} className="rounded-full border border-border px-4 py-2 text-brand hover:bg-brand-soft">Older →</Link>}
        </nav>
      )}
    </div>
  );
}
