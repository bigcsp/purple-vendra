"use client";

import { BriefcaseBusiness, Check, Palette } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Notice } from "@/components/ui";
import { PRO_MODES, type ProMode } from "@/lib/pro";
import { choosePageType } from "@/server/actions/pro";

const OPTIONS: { mode: ProMode; icon: typeof Palette; points: string[] }[] = [
  {
    mode: "professional",
    icon: BriefcaseBusiness,
    points: ["Experience, education & certifications", "Skills and languages", "Services with Hire me button"],
  },
  {
    mode: "creative_space",
    icon: Palette,
    points: ["Large cover and visual layout", "Services, hours and service areas", "Photo & video gallery (coming next)"],
  },
];

/** First-time setup: choose how the professional page is presented. Can be changed later. */
export function ModeChooser({ current }: { current?: ProMode | null }) {
  const router = useRouter();
  const [picked, setPicked] = useState<ProMode | null>(current ?? null);
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();

  return (
    <div className="space-y-5">
      <div role="radiogroup" aria-label="Page type" className="grid gap-4 md:grid-cols-2">
        {OPTIONS.map(({ mode, icon: Icon, points }) => {
          const m = PRO_MODES[mode];
          const on = picked === mode;
          return (
            <button
              key={mode}
              type="button"
              role="radio"
              aria-checked={on}
              onClick={() => setPicked(mode)}
              className={`group relative flex h-full flex-col rounded-3xl border bg-card p-6 text-left transition ${
                on ? "border-brand ring-2 ring-brand/30" : "border-border hover:border-brand/50"
              }`}
            >
              <span className={`flex h-11 w-11 items-center justify-center rounded-2xl ${on ? "bg-brand text-white" : "bg-brand-soft text-brand"}`}>
                <Icon className="h-5 w-5" strokeWidth={1.9} aria-hidden />
              </span>
              <span className="mt-4 text-lg font-semibold text-brand-strong">{m.title}</span>
              <span className="mt-1 text-sm text-muted">{m.tagline}</span>
              <ul className="mt-4 space-y-1.5 text-sm">
                {points.map((p) => (
                  <li key={p} className="flex items-start gap-2">
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-brand" strokeWidth={2.2} aria-hidden />
                    {p}
                  </li>
                ))}
              </ul>
              <span className="mt-auto pt-5 text-xs text-muted">
                <span className="font-medium text-foreground">Best for:</span> {m.bestFor}
              </span>
              {on && (
                <span className="absolute right-5 top-5 flex h-6 w-6 items-center justify-center rounded-full bg-brand text-white">
                  <Check className="h-3.5 w-3.5" strokeWidth={3} aria-hidden />
                </span>
              )}
            </button>
          );
        })}
      </div>
      {error && <Notice tone="error">{error}</Notice>}
      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          disabled={!picked || pending || picked === current}
          onClick={() =>
            picked &&
            start(async () => {
              setError(undefined);
              const r = await choosePageType(picked);
              if (r.error) return setError(r.error);
              router.refresh();
            })
          }
          className="inline-flex items-center justify-center rounded-xl bg-brand px-5 py-2.5 font-medium text-white transition hover:bg-brand-deep disabled:opacity-50"
        >
          {pending ? "Saving…" : current ? "Switch page type" : "Continue"}
        </button>
        <p className="text-xs text-muted">You can switch at any time. Nothing you add is lost.</p>
      </div>
    </div>
  );
}
