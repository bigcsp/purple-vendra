"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { acceptOffer, closeRequest, declineOffer } from "@/app/actions/requests";
import { Notice } from "@/components/ui";
import { formatNaira } from "@/lib/money";
import type { RequestOffer } from "@/lib/requests";

/** The buyer's view: offers side by side, accept (opens chat) or decline. */
export function OfferList({ requestId, offers, open }: { requestId: string; offers: RequestOffer[]; open: boolean }) {
  const router = useRouter();
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();
  const [busyId, setBusyId] = useState<string>();

  const act = (id: string, fn: () => Promise<{ error?: string; id?: string }>, then?: (id?: string) => void) => {
    setBusyId(id);
    start(async () => {
      setError(undefined);
      const r = await fn();
      setBusyId(undefined);
      if (r.error) return setError(r.error);
      if (then) then(r.id);
      else router.refresh();
    });
  };

  const waiting = offers.filter((o) => o.status === "sent");

  return (
    <div className="space-y-4">
      {offers.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-border bg-card p-6 text-center text-sm text-muted">
          No offers yet. Sellers who do this kind of work can see your request now.
        </div>
      ) : (
        <ul className="grid gap-3">
          {offers.map((o) => (
            <li
              key={o.id}
              className={`rounded-3xl border bg-card p-4 sm:p-5 ${o.status === "accepted" ? "border-green-300 ring-2 ring-green-100" : "border-border"} ${o.status === "declined" ? "opacity-60" : ""}`}
            >
              <div className="flex flex-wrap items-start gap-3">
                {o.seller_avatar ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={o.seller_avatar} alt="" className="h-11 w-11 rounded-full object-cover" />
                ) : (
                  <span className="flex h-11 w-11 items-center justify-center rounded-full bg-brand-soft font-bold text-brand">
                    {o.seller_name.slice(0, 1).toUpperCase()}
                  </span>
                )}
                <div className="min-w-0 flex-1">
                  <Link href={`/shop/${o.seller_username}`} className="font-semibold text-brand-strong hover:underline">
                    {o.seller_name}
                  </Link>
                  {o.seller_verified && <span className="ml-1 text-green-700" title="ID verified">✓</span>}
                  <p className="text-xs text-muted">
                    {o.seller_rating_count > 0 ? `★ ${Number(o.seller_rating).toFixed(1)} (${o.seller_rating_count})` : "New seller"}
                    {o.seller_state && <> · {o.seller_state}</>}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-brand-strong">{formatNaira(o.price_kobo)}</p>
                  {o.delivery_days && <p className="text-xs text-muted">Ready in {o.delivery_days} day{o.delivery_days === 1 ? "" : "s"}</p>}
                </div>
              </div>
              <p className="mt-3 whitespace-pre-line text-sm">{o.message}</p>
              {o.listing_id && o.listing_title && (
                <Link href={`/l/${o.listing_id}`} className="mt-2 inline-block text-sm text-brand underline">
                  See their listing: {o.listing_title}
                </Link>
              )}
              <div className="mt-4 flex flex-wrap items-center gap-2">
                {o.status === "accepted" && (
                  <>
                    <span className="rounded-full bg-green-50 px-3 py-1 text-sm font-medium text-green-800">Accepted</span>
                    {o.chat_id && (
                      <Link href={`/messages/${o.chat_id}`} className="rounded-full bg-brand px-4 py-1.5 text-sm font-medium text-white hover:bg-brand-deep">
                        Open chat
                      </Link>
                    )}
                  </>
                )}
                {o.status === "declined" && <span className="text-sm text-muted">Declined</span>}
                {o.status === "sent" && open && (
                  <>
                    <button
                      type="button"
                      disabled={pending}
                      onClick={() => {
                        if (!window.confirm(`Accept ${o.seller_name}'s offer of ${formatNaira(o.price_kobo)}? This closes your request, declines the other offers and opens a chat.`)) return;
                        act(o.id, () => acceptOffer(o.id, requestId), (chat) => router.push(chat ? `/messages/${chat}` : `/requests/${requestId}`));
                      }}
                      className="rounded-full bg-brand px-4 py-1.5 text-sm font-medium text-white hover:bg-brand-deep disabled:opacity-60"
                    >
                      {busyId === o.id ? "Working…" : "Accept & chat"}
                    </button>
                    <button
                      type="button"
                      disabled={pending}
                      onClick={() => act(o.id, () => declineOffer(o.id, requestId))}
                      className="rounded-full border border-border px-4 py-1.5 text-sm font-medium text-muted hover:text-brand"
                    >
                      Decline
                    </button>
                  </>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}

      {error && <Notice tone="error">{error}</Notice>}

      {open && (
        <button
          type="button"
          disabled={pending}
          onClick={() => {
            if (!window.confirm(waiting.length ? "Close this request? Waiting offers will be declined." : "Close this request?")) return;
            act("close", () => closeRequest(requestId));
          }}
          className="text-sm text-muted underline hover:text-brand"
        >
          Close request
        </button>
      )}
    </div>
  );
}
