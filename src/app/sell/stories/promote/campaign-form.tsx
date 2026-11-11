"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { createCampaign } from "@/app/actions/campaigns";
import { Notice, buttonClass } from "@/components/ui";
import { formatNaira, nairaToKobo } from "@/lib/money";
import { NIGERIAN_STATES } from "@/lib/nigeria";

type Video = { id: string; title: string; poster: string | null };
type Category = { id: number; name: string };

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";
const DURATIONS = [3, 7, 14, 30];

export function CampaignForm({ videos, categories, initialVideo }: { videos: Video[]; categories: Category[]; initialVideo?: string }) {
  const router = useRouter();
  const [videoId, setVideoId] = useState(initialVideo && videos.some((v) => v.id === initialVideo) ? initialVideo : videos[0]?.id ?? "");
  const [categoryIds, setCategoryIds] = useState<number[]>([]);
  const [states, setStates] = useState<string[]>([]);
  const [note, setNote] = useState("");
  const [days, setDays] = useState(7);
  const [budget, setBudget] = useState("5000");
  const [error, setError] = useState<string>();
  const [done, setDone] = useState(false);
  const [pending, start] = useTransition();

  const kobo = nairaToKobo(budget);
  const perDay = kobo ? kobo / days : 0;

  if (videos.length === 0) {
    return <p className="text-sm text-muted">Publish a story first, then come back to promote it.</p>;
  }

  if (done) {
    return (
      <div className="space-y-3">
        <Notice tone="success">
          Campaign created. It&apos;s <strong>awaiting payment</strong>. The Purple Vendra team will send you payment details,
          and your campaign starts the moment payment is confirmed. You&apos;ll see it change to &quot;Running&quot; below.
        </Notice>
        <button onClick={() => setDone(false)} className="text-sm font-medium text-brand hover:underline">Create another</button>
      </div>
    );
  }

  const toggle = <T,>(list: T[], item: T) => (list.includes(item) ? list.filter((x) => x !== item) : [...list, item]);

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        setError(undefined);
        start(async () => {
          const r = await createCampaign({ videoId, categoryIds, states, audienceNote: note, durationDays: days, budget });
          if (r.error) return setError(r.error);
          setDone(true);
          router.refresh();
        });
      }}
      className="space-y-5"
    >
      <fieldset>
        <legend className="text-sm font-medium text-brand-strong">1. Which story?</legend>
        <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
          {videos.map((v) => (
            <button type="button" key={v.id} onClick={() => setVideoId(v.id)}
              className={`w-24 shrink-0 overflow-hidden rounded-xl border-2 text-left ${videoId === v.id ? "border-brand" : "border-transparent"}`}>
              {v.poster ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={v.poster} alt="" className="aspect-[9/16] w-full object-cover" />
              ) : (
                <span className="block aspect-[9/16] bg-panel" />
              )}
              <span className="block truncate p-1 text-xs">{v.title}</span>
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset>
        <legend className="text-sm font-medium text-brand-strong">2. Who should see it?</legend>
        <p className="text-xs text-muted">Leave both empty to reach everyone browsing Vendra Stories.</p>
        <p className="mt-2 text-xs font-medium">Buyers browsing these categories</p>
        <div className="mt-1 flex flex-wrap gap-2">
          {categories.map((c) => (
            <button type="button" key={c.id} onClick={() => setCategoryIds((l) => toggle(l, c.id))}
              className={`rounded-full px-3 py-1 text-xs ${categoryIds.includes(c.id) ? "bg-brand text-white" : "border border-border bg-card"}`}>
              {c.name}
            </button>
          ))}
        </div>
        <p className="mt-3 text-xs font-medium">Signed-in buyers in these states</p>
        <div className="mt-1 flex max-h-28 flex-wrap gap-1.5 overflow-y-auto">
          {NIGERIAN_STATES.map((s) => (
            <button type="button" key={s} onClick={() => setStates((l) => toggle(l, s))}
              className={`rounded-full px-2.5 py-0.5 text-xs ${states.includes(s) ? "bg-brand text-white" : "border border-border bg-card"}`}>
              {s}
            </button>
          ))}
        </div>
        <label className="mt-3 block">
          <span className="text-xs font-medium">Anything else about your ideal buyer? (optional)</span>
          <input className={inputClass} value={note} maxLength={300} onChange={(e) => setNote(e.target.value)}
            placeholder="Brides-to-be, wedding guests, aso-ebi groups" />
        </label>
      </fieldset>

      <div className="grid gap-4 sm:grid-cols-2">
        <fieldset>
          <legend className="text-sm font-medium text-brand-strong">3. How long?</legend>
          <div className="mt-2 flex gap-2">
            {DURATIONS.map((d) => (
              <button type="button" key={d} onClick={() => setDays(d)}
                className={`flex-1 rounded-xl px-3 py-2 text-sm ${days === d ? "bg-brand text-white" : "border border-border bg-card"}`}>
                {d} days
              </button>
            ))}
          </div>
        </fieldset>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">4. Budget (₦)</span>
          <input className={inputClass} inputMode="decimal" value={budget} onChange={(e) => setBudget(e.target.value)} />
          <span className="mt-1 block text-xs text-muted">
            {kobo ? `≈ ${formatNaira(Math.round(perDay))} a day · min ₦1,000` : "Enter an amount (min ₦1,000)"}
          </span>
        </label>
      </div>

      {error && <Notice tone="error">{error}</Notice>}
      <button className={`${buttonClass} sm:w-auto`} disabled={pending || !videoId}>
        {pending ? "Creating…" : `Create campaign${kobo ? ` · ${formatNaira(kobo)}` : ""}`}
      </button>
      <p className="text-xs text-muted">
        Promoted stories appear first in Vendra Stories for the buyers you chose, with a &quot;Promoted&quot; label. You only pay
        once the team confirms your campaign. Online payment is coming with checkout.
      </p>
    </form>
  );
}
