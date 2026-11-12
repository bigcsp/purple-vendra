"use client";

import { useState, useTransition } from "react";
import { submitReport } from "@/server/actions/report";
import { Notice, buttonClass } from "@/components/ui";
import { REPORT_REASONS, type ReportReason } from "@/lib/report-reasons";

/**
 * "Report" link that opens a short form. Use on listing pages
 * (listingId), shop/profile pages (userId) and Purple Stories (videoId).
 */
export function ReportButton({
  listingId,
  userId,
  videoId,
  requestId,
  startOpen = false,
  label,
}: {
  label?: string;
  requestId?: string;
  listingId?: string;
  userId?: string;
  videoId?: string;
  startOpen?: boolean;
}) {
  const [open, setOpen] = useState(startOpen);
  const [reason, setReason] = useState<ReportReason | "">("");
  const [details, setDetails] = useState("");
  const [error, setError] = useState<string>();
  const [done, setDone] = useState(false);
  const [pending, startTransition] = useTransition();

  if (done) {
    return (
      <Notice tone="success">
        Thanks for telling us. Our team will look into it. Never pay a seller outside Purple Shop.
      </Notice>
    );
  }

  if (!open) {
    return (
      <button onClick={() => setOpen(true)} className="text-sm text-muted underline hover:text-brand">
        {label ?? `Report ${listingId ? "this listing" : videoId ? "this video" : requestId ? "this request" : "this seller"}`}
      </button>
    );
  }

  function send(e: React.FormEvent) {
    e.preventDefault();
    if (!reason) return setError("Choose a reason.");
    startTransition(async () => {
      const result = await submitReport({ listingId, userId, videoId, requestId, reason, details });
      if (result.error) setError(result.error);
      else setDone(true);
    });
  }

  return (
    <form onSubmit={send} className="space-y-3 rounded-2xl border border-border bg-card p-4">
      <p className="text-sm font-medium text-brand-strong">What&apos;s wrong?</p>
      <div className="space-y-1.5">
        {(Object.keys(REPORT_REASONS) as ReportReason[]).map((key) => (
          <label key={key} className="flex items-center gap-2 text-sm">
            <input
              type="radio"
              name="reason"
              value={key}
              checked={reason === key}
              onChange={() => setReason(key)}
              className="accent-[var(--brand)]"
            />
            {REPORT_REASONS[key]}
          </label>
        ))}
      </div>
      <textarea
        value={details}
        onChange={(e) => setDetails(e.target.value)}
        maxLength={2000}
        rows={3}
        placeholder="Anything that helps us check (optional)"
        className="block w-full rounded-xl border border-border px-3 py-2 text-sm outline-none focus:border-brand"
      />
      {error && <Notice tone="error">{error}</Notice>}
      <div className="flex gap-2">
        <button className={`${buttonClass} sm:w-auto`} disabled={pending}>
          {pending ? "Sending…" : "Send report"}
        </button>
        <button type="button" onClick={() => setOpen(false)} className="px-3 text-sm text-muted">
          Cancel
        </button>
      </div>
    </form>
  );
}
