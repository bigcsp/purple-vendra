"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { sendOffer, withdrawOffer } from "@/server/actions/requests";
import { Notice, buttonClass } from "@/components/ui";
import { CONTACT_MESSAGES, contactProblem } from "@/lib/contact-guard";
import { formatNaira } from "@/lib/money";

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

/** Seller's offer: send, edit or withdraw. */
export function OfferForm({
  requestId,
  listings,
  existing,
}: {
  requestId: string;
  listings: { id: string; title: string }[];
  existing: { id: string; status: string; priceKobo: number; days: number | null; message: string; listingId: string | null } | null;
}) {
  const router = useRouter();
  const live = existing && existing.status === "sent";
  const [editing, setEditing] = useState(!live);
  const [price, setPrice] = useState(existing ? String(existing.priceKobo / 100) : "");
  const [days, setDays] = useState(existing?.days ? String(existing.days) : "");
  const [message, setMessage] = useState(existing?.message ?? "");
  const [listingId, setListingId] = useState(existing?.listingId ?? "");
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();
  const problem = contactProblem(message);

  if (live && !editing) {
    return (
      <div className="space-y-3">
        <Notice tone="success">
          Your offer of {formatNaira(existing.priceKobo)} ({existing.days} day{existing.days === 1 ? "" : "s"}) was sent. The
          buyer will see it with your shop name and rating.
        </Notice>
        <p className="whitespace-pre-line rounded-2xl bg-brand-soft/50 p-3 text-sm">{existing.message}</p>
        <div className="flex flex-wrap gap-3 text-sm">
          <button type="button" onClick={() => setEditing(true)} className="font-medium text-brand underline">Edit offer</button>
          <button
            type="button"
            disabled={pending}
            onClick={() =>
              start(async () => {
                if (!window.confirm("Withdraw your offer?")) return;
                const r = await withdrawOffer(existing.id, requestId);
                if (r.error) setError(r.error);
                router.refresh();
              })
            }
            className="text-muted underline hover:text-brand"
          >
            Withdraw
          </button>
        </div>
        {error && <Notice tone="error">{error}</Notice>}
      </div>
    );
  }

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (problem) return setError(CONTACT_MESSAGES[problem]);
    start(async () => {
      setError(undefined);
      const r = await sendOffer({ requestId, price, days, message, listingId });
      if (r.signIn) return router.push(`/signup?reason=offer&next=/requests/${requestId}`);
      if (r.error) return setError(r.error);
      setEditing(false);
      router.refresh();
    });
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Your price (₦)</span>
          <input value={price} onChange={(e) => setPrice(e.target.value)} inputMode="decimal" required placeholder="e.g. 135000" className={inputClass} />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Ready in (days)</span>
          <input value={days} onChange={(e) => setDays(e.target.value.replace(/\D/g, ""))} inputMode="numeric" required placeholder="e.g. 7" className={inputClass} />
        </label>
      </div>
      <label className="block">
        <span className="text-sm font-medium text-brand-strong">Message to the buyer</span>
        <textarea value={message} onChange={(e) => setMessage(e.target.value)} rows={4} maxLength={1000} required
          placeholder="What you'll deliver, materials, how you'll handle delivery or the visit…" className={inputClass}
          aria-invalid={problem ? true : undefined} />
        <span className={`mt-1 block text-xs ${problem ? "text-red-700" : "text-muted"}`}>
          {problem ? CONTACT_MESSAGES[problem] : `${message.length}/1000 · No phone numbers, links or bank details: the buyer pays through escrow.`}
        </span>
      </label>
      {listings.length > 0 && (
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Show one of your listings <span className="font-normal text-muted">(optional)</span></span>
          <select value={listingId} onChange={(e) => setListingId(e.target.value)} className={inputClass}>
            <option value="">None</option>
            {listings.map((l) => <option key={l.id} value={l.id}>{l.title}</option>)}
          </select>
        </label>
      )}
      {error && <Notice tone="error">{error}</Notice>}
      <div className="flex flex-wrap gap-3">
        <button disabled={pending || !!problem} className={`${buttonClass} sm:w-auto`}>
          {pending ? "Sending…" : live ? "Update offer" : "Send offer"}
        </button>
        {live && (
          <button type="button" onClick={() => setEditing(false)} className="text-sm text-muted underline">Cancel</button>
        )}
      </div>
    </form>
  );
}
