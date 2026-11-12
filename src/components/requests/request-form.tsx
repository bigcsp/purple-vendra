"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { createRequest, updateRequest, type RequestInput } from "@/app/actions/requests";
import { Notice, buttonClass } from "@/components/ui";
import { CONTACT_MESSAGES, contactProblem } from "@/lib/contact-guard";
import { NIGERIAN_STATES } from "@/lib/nigeria";

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

type Category = { id: number; name: string; section: string };

export function RequestForm({
  categories,
  initial,
  requestId,
}: {
  categories: Category[];
  initial: RequestInput;
  requestId?: string;
}) {
  const router = useRouter();
  const [v, setV] = useState<RequestInput>(initial);
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();
  const set = <K extends keyof RequestInput>(k: K, value: RequestInput[K]) => setV((x) => ({ ...x, [k]: value }));

  const problem = contactProblem(`${v.title} ${v.description} ${v.city}`);
  // Date limits for the "needed by" picker (computed once).
  const [{ today, max }] = useState(() => {
    const now = Date.now();
    return {
      today: new Date(now).toISOString().slice(0, 10),
      max: new Date(now + 180 * 86_400_000).toISOString().slice(0, 10),
    };
  });

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (problem) return setError(CONTACT_MESSAGES[problem]);
    start(async () => {
      setError(undefined);
      const r = requestId ? await updateRequest(requestId, v) : await createRequest(v);
      if (r.signIn) return router.push("/signup?reason=request&next=/requests/new");
      if (r.error || !r.id) return setError(r.error ?? "Couldn't save. Please try again.");
      router.push(`/requests/${r.id}${requestId ? "" : "?posted=1"}`);
    });
  }

  const sections = [...new Set(categories.map((c) => c.section))];

  return (
    <form onSubmit={submit} className="space-y-5">
      <label className="block">
        <span className="text-sm font-medium text-brand-strong">What do you need?</span>
        <input value={v.title} onChange={(e) => set("title", e.target.value)} maxLength={120} required
          placeholder="e.g. Blue agbada for a December wedding" className={inputClass} />
      </label>

      <label className="block">
        <span className="text-sm font-medium text-brand-strong">Describe it</span>
        <textarea value={v.description} onChange={(e) => set("description", e.target.value)} rows={6} maxLength={2000} required
          placeholder="Size, colours, quantity, style, what the job involves… The more detail, the better the offers."
          className={inputClass} />
        <span className="mt-1 block text-xs text-muted">{v.description.length}/2000 · Don&apos;t include phone numbers, emails or bank details.</span>
      </label>

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Category</span>
          <select value={v.categoryId} onChange={(e) => set("categoryId", Number(e.target.value))} className={inputClass} required>
            {sections.map((s) => (
              <optgroup key={s} label={s}>
                {categories.filter((c) => c.section === s).map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </optgroup>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Budget (₦)</span>
          <input value={v.budget} onChange={(e) => set("budget", e.target.value)} inputMode="decimal" placeholder="Leave empty for open budget" className={inputClass} />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">State</span>
          <select value={v.state} onChange={(e) => set("state", e.target.value)} className={inputClass} required>
            <option value="">Choose…</option>
            {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Area or city <span className="font-normal text-muted">(optional)</span></span>
          <input value={v.city} onChange={(e) => set("city", e.target.value)} maxLength={60} placeholder="e.g. Lekki" className={inputClass} />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm font-medium text-brand-strong">Needed by <span className="font-normal text-muted">(optional)</span></span>
          <input type="date" value={v.deadline} min={today} max={max} onChange={(e) => set("deadline", e.target.value)} className={inputClass} />
          <span className="mt-1 block text-xs text-muted">Requests stay open for 14 days, or until this date if it&apos;s sooner.</span>
        </label>
      </div>

      {(problem || error) && <Notice tone="error">{problem ? CONTACT_MESSAGES[problem] : error}</Notice>}

      <div className="rounded-2xl bg-brand-soft/60 p-3 text-xs text-brand-strong">
        Sellers see your request but not your name. You choose who to chat with, and you pay only through Purple Shop
        escrow.
      </div>

      <button disabled={pending || !!problem} className={buttonClass}>
        {pending ? "Saving…" : requestId ? "Save changes" : "Post request"}
      </button>
    </form>
  );
}
