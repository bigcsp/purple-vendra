"use client";

import { ArrowDown, ArrowUp, Award, BadgeCheck, BriefcaseBusiness, GraduationCap, Pencil, Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Notice } from "@/components/ui";
import { ENTRY_KINDS, PRO_LIMITS, yearRange, type ProEntry, type ProEntryKind } from "@/lib/pro";
import { deleteEntry, reorderEntries, saveEntry, type EntryInput } from "@/server/actions/pro";

export const ENTRY_ICONS: Record<ProEntryKind, typeof Award> = {
  experience: BriefcaseBusiness,
  education: GraduationCap,
  certification: BadgeCheck,
  achievement: Award,
};

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

function blank(kind: ProEntryKind): EntryInput {
  return { kind, title: "", organisation: "", location: "", startYear: "", endYear: "", isCurrent: false, description: "" };
}

function toInput(e: ProEntry): EntryInput {
  return {
    id: e.id,
    kind: e.kind,
    title: e.title,
    organisation: e.organisation ?? "",
    location: e.location ?? "",
    startYear: e.start_year ? String(e.start_year) : "",
    endYear: e.end_year ? String(e.end_year) : "",
    isCurrent: e.is_current,
    description: e.description ?? "",
  };
}

/** One career section (experience, education, certifications or achievements) with add, edit, reorder and delete. */
export function EntrySection({ kind, entries }: { kind: ProEntryKind; entries: ProEntry[] }) {
  const meta = ENTRY_KINDS[kind];
  const Icon = ENTRY_ICONS[kind];
  const router = useRouter();
  const [editing, setEditing] = useState<EntryInput | null>(null);
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();
  const full = entries.length >= PRO_LIMITS.entriesPerSection;

  function run(fn: () => Promise<{ error?: string }>, after?: () => void) {
    start(async () => {
      setError(undefined);
      const r = await fn();
      if (r.error) return setError(r.error);
      after?.();
      router.refresh();
    });
  }

  function move(i: number, dir: -1 | 1) {
    const ids = entries.map((e) => e.id);
    const j = i + dir;
    if (j < 0 || j >= ids.length) return;
    [ids[i], ids[j]] = [ids[j], ids[i]];
    run(() => reorderEntries(kind, ids));
  }

  return (
    <section id={kind} className="scroll-mt-24 rounded-3xl border border-border bg-card p-6 sm:p-8">
      <header className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-soft text-brand">
            <Icon className="h-5 w-5" strokeWidth={1.9} aria-hidden />
          </span>
          <div>
            <h2 className="text-lg font-semibold text-brand-strong">{meta.title}</h2>
            <p className="text-xs text-muted">{entries.length === 0 ? meta.empty : `${entries.length} added`}</p>
          </div>
        </div>
        {!editing && !full && (
          <button
            type="button"
            onClick={() => setEditing(blank(kind))}
            className="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm font-medium text-brand hover:bg-brand-soft"
          >
            <Plus className="h-4 w-4" aria-hidden /> Add
          </button>
        )}
      </header>

      {error && <div className="mt-4"><Notice tone="error">{error}</Notice></div>}

      {editing && !editing.id && (
        <EntryForm value={editing} onChange={setEditing} pending={pending}
          onCancel={() => setEditing(null)}
          onSave={() => run(() => saveEntry(editing), () => setEditing(null))} />
      )}

      {entries.length > 0 && (
        <ol className="mt-5 divide-y divide-border">
          {entries.map((e, i) =>
            editing?.id === e.id ? (
              <li key={e.id} className="py-2">
                <EntryForm value={editing} onChange={setEditing} pending={pending}
                  onCancel={() => setEditing(null)}
                  onSave={() => run(() => saveEntry(editing), () => setEditing(null))} />
              </li>
            ) : (
              <li key={e.id} className="flex gap-3 py-4">
                <div className="min-w-0 flex-1">
                  <p className="font-medium text-foreground">{e.title}</p>
                  {(e.organisation || e.location) && (
                    <p className="text-sm text-muted">{[e.organisation, e.location].filter(Boolean).join(" · ")}</p>
                  )}
                  {yearRange(e) && <p className="text-xs tabular-nums text-muted">{yearRange(e)}</p>}
                  {e.description && <p className="mt-1.5 line-clamp-2 text-sm text-foreground/80">{e.description}</p>}
                </div>
                <div className="flex shrink-0 items-start gap-0.5 text-muted">
                  <IconButton label="Move up" disabled={pending || i === 0} onClick={() => move(i, -1)}><ArrowUp className="h-4 w-4" /></IconButton>
                  <IconButton label="Move down" disabled={pending || i === entries.length - 1} onClick={() => move(i, 1)}><ArrowDown className="h-4 w-4" /></IconButton>
                  <IconButton label="Edit" disabled={pending} onClick={() => setEditing(toInput(e))}><Pencil className="h-4 w-4" /></IconButton>
                  <IconButton
                    label="Delete"
                    disabled={pending}
                    onClick={() => confirm(`Delete "${e.title}"?`) && run(() => deleteEntry(e.id))}
                  >
                    <Trash2 className="h-4 w-4" />
                  </IconButton>
                </div>
              </li>
            ),
          )}
        </ol>
      )}
      {full && <p className="mt-3 text-xs text-muted">You&apos;ve reached {PRO_LIMITS.entriesPerSection} items in this section.</p>}
    </section>
  );
}

function IconButton({ label, children, ...props }: { label: string; children: React.ReactNode } & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button type="button" aria-label={label} title={label} {...props}
      className="rounded-lg p-2 hover:bg-brand-soft hover:text-brand disabled:opacity-30 disabled:hover:bg-transparent">
      {children}
    </button>
  );
}

function EntryForm({
  value: v,
  onChange,
  onSave,
  onCancel,
  pending,
}: {
  value: EntryInput;
  onChange: (v: EntryInput) => void;
  onSave: () => void;
  onCancel: () => void;
  pending: boolean;
}) {
  const meta = ENTRY_KINDS[v.kind];
  const set = <K extends keyof EntryInput>(k: K, val: EntryInput[K]) => onChange({ ...v, [k]: val });
  const id = (k: string) => `${v.kind}-${v.id ?? "new"}-${k}`;

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        onSave();
      }}
      className="mt-5 grid gap-4 rounded-2xl border border-brand/30 bg-brand-soft/40 p-4 sm:grid-cols-2 sm:p-5"
    >
      <label className="block sm:col-span-2" htmlFor={id("title")}>
        <span className="text-sm font-medium text-brand-strong">{meta.titleLabel} *</span>
        <input id={id("title")} required maxLength={120} autoFocus value={v.title} onChange={(e) => set("title", e.target.value)} className={inputClass} />
      </label>
      <label className="block" htmlFor={id("org")}>
        <span className="text-sm font-medium text-brand-strong">{meta.orgLabel}</span>
        <input id={id("org")} maxLength={120} value={v.organisation} onChange={(e) => set("organisation", e.target.value)} className={inputClass} />
      </label>
      <label className="block" htmlFor={id("loc")}>
        <span className="text-sm font-medium text-brand-strong">Location</span>
        <input id={id("loc")} maxLength={80} placeholder="e.g. Lagos or Remote" value={v.location} onChange={(e) => set("location", e.target.value)} className={inputClass} />
      </label>
      <div className="grid grid-cols-2 gap-3 sm:col-span-2">
        <label className="block" htmlFor={id("start")}>
          <span className="text-sm font-medium text-brand-strong">{meta.dated ? "Start year" : "Year"}</span>
          <input id={id("start")} inputMode="numeric" pattern="\d{4}" maxLength={4} placeholder="2021" value={v.startYear}
            onChange={(e) => set("startYear", e.target.value.replace(/\D/g, ""))} className={inputClass} />
        </label>
        {meta.dated && (
          <label className="block" htmlFor={id("end")}>
            <span className="text-sm font-medium text-brand-strong">End year</span>
            <input id={id("end")} inputMode="numeric" pattern="\d{4}" maxLength={4} placeholder={v.isCurrent ? "Present" : "2024"}
              disabled={v.isCurrent} value={v.isCurrent ? "" : v.endYear}
              onChange={(e) => set("endYear", e.target.value.replace(/\D/g, ""))} className={`${inputClass} disabled:opacity-60`} />
          </label>
        )}
      </div>
      {meta.dated && v.kind !== "certification" && (
        <label className="flex items-center gap-2 text-sm sm:col-span-2">
          <input type="checkbox" checked={v.isCurrent} onChange={(e) => set("isCurrent", e.target.checked)} className="h-4 w-4 accent-[var(--brand)]" />
          {v.kind === "education" ? "I'm currently studying here" : "I currently work here"}
        </label>
      )}
      <label className="block sm:col-span-2" htmlFor={id("desc")}>
        <span className="flex justify-between text-sm font-medium text-brand-strong">
          Description <span className="text-xs font-normal tabular-nums text-muted">{v.description.length}/1000</span>
        </span>
        <textarea id={id("desc")} rows={3} maxLength={1000} value={v.description} onChange={(e) => set("description", e.target.value)}
          placeholder="What you did, the results, tools you used." className={inputClass} />
      </label>
      <div className="flex gap-2 sm:col-span-2">
        <button type="submit" disabled={pending}
          className="rounded-xl bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep disabled:opacity-60">
          {pending ? "Saving…" : "Save"}
        </button>
        <button type="button" onClick={onCancel} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">
          Cancel
        </button>
      </div>
    </form>
  );
}
