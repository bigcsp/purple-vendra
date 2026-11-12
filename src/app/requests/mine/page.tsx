import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { getCurrentUser } from "@/server/auth/session";
import { formatNaira } from "@/lib/money";
import { getMine, postedAgo, timeLeft } from "@/server/queries/requests";

export const metadata: Metadata = { title: "My requests & offers · Purple Shop" };

export default function MinePage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <Mine />
      </Suspense>
    </PageShell>
  );
}

const REQUEST_STATUS = { open: ["Open", "bg-green-50 text-green-800"], closed: ["Closed", "bg-brand-soft text-muted"], expired: ["Expired", "bg-brand-soft text-muted"] } as const;
const OFFER_STATUS = {
  sent: ["Waiting for buyer", "bg-amber-50 text-amber-800"],
  accepted: ["Accepted", "bg-green-50 text-green-800"],
  declined: ["Not chosen", "bg-brand-soft text-muted"],
  withdrawn: ["Withdrawn", "bg-brand-soft text-muted"],
} as const;

async function Mine() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/requests/mine");
  const { requests, offers } = await getMine();
  const isSeller = user.role !== "buyer";

  return (
    <div className="space-y-10">
      <section>
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-brand-strong">My requests</h1>
            <p className="text-sm text-muted">What you&apos;ve asked for, and the offers you received.</p>
          </div>
          <Link href="/requests/new" className="rounded-full bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-deep">Post a request</Link>
        </div>
        {requests.length === 0 ? (
          <p className="mt-4 rounded-3xl border border-dashed border-border bg-card p-6 text-center text-sm text-muted">
            You haven&apos;t posted a request yet. Need something made, designed or fixed? Post it and get offers.
          </p>
        ) : (
          <ul className="mt-4 divide-y divide-border overflow-hidden rounded-3xl border border-border bg-card">
            {requests.map((r) => {
              const [label, tone] = REQUEST_STATUS[r.status];
              return (
                <li key={r.id}>
                  <Link href={`/requests/${r.id}`} className="flex items-center gap-3 px-4 py-3.5 hover:bg-brand-soft/50">
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-medium">{r.title}</span>
                      <span className="block text-xs text-muted">
                        Posted {postedAgo(r.created_at)}{r.status === "open" && <> · {timeLeft(r.expires_at)}</>} · {r.offer_count} offer{r.offer_count === 1 ? "" : "s"}
                      </span>
                    </span>
                    {r.status === "open" && r.new_offers > 0 && (
                      <span className="rounded-full bg-brand px-2.5 py-0.5 text-xs font-bold text-white">{r.new_offers} to review</span>
                    )}
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${tone}`}>{label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      {isSeller && (
        <section>
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-brand-strong">Offers I sent</h2>
              <p className="text-sm text-muted">Your offers on buyers&apos; requests.</p>
            </div>
            <Link href="/requests?view=matches" className="rounded-full border border-border px-4 py-2 text-sm font-medium text-brand hover:bg-brand-soft">Find requests</Link>
          </div>
          {offers.length === 0 ? (
            <p className="mt-4 rounded-3xl border border-dashed border-border bg-card p-6 text-center text-sm text-muted">
              No offers yet. Browse the board for requests that match what you do.
            </p>
          ) : (
            <ul className="mt-4 divide-y divide-border overflow-hidden rounded-3xl border border-border bg-card">
              {offers.map((o) => {
                const [label, tone] = OFFER_STATUS[o.offer_status];
                return (
                  <li key={o.offer_id} className="flex items-center gap-3 px-4 py-3.5">
                    <Link href={`/requests/${o.request_id}`} className="min-w-0 flex-1 hover:underline">
                      <span className="block truncate font-medium">{o.title}</span>
                      <span className="block text-xs text-muted">{formatNaira(o.price_kobo)} · sent {postedAgo(o.created_at)}</span>
                    </Link>
                    {o.chat_id && o.offer_status === "accepted" && (
                      <Link href={`/messages/${o.chat_id}`} className="rounded-full bg-brand px-3 py-1 text-xs font-medium text-white hover:bg-brand-deep">Chat</Link>
                    )}
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${tone}`}>{label}</span>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      )}
    </div>
  );
}
