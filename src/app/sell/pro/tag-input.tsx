"use client";

import { X } from "lucide-react";
import { useState } from "react";

/** Chip input: type and press Enter or comma to add; Backspace on empty removes the last. */
export function TagInput({
  id,
  label,
  hint,
  value,
  onChange,
  max,
  maxLength,
  placeholder,
  suggestions = [],
}: {
  id: string;
  label: string;
  hint?: string;
  value: string[];
  onChange: (v: string[]) => void;
  max: number;
  maxLength: number;
  placeholder: string;
  suggestions?: string[];
}) {
  const [draft, setDraft] = useState("");
  const full = value.length >= max;

  function add(raw: string) {
    const t = raw.replace(/\s+/g, " ").trim().slice(0, maxLength);
    if (!t || full || value.some((v) => v.toLowerCase() === t.toLowerCase())) return setDraft("");
    onChange([...value, t]);
    setDraft("");
  }

  const unused = suggestions.filter((s) => !value.some((v) => v.toLowerCase() === s.toLowerCase())).slice(0, 8);

  return (
    <div>
      <div className="flex items-baseline justify-between gap-2">
        <label htmlFor={id} className="text-sm font-medium text-brand-strong">{label}</label>
        <span className="text-xs tabular-nums text-muted">{value.length}/{max}</span>
      </div>
      <div className="mt-1 flex flex-wrap gap-2 rounded-xl border border-border bg-card p-2 focus-within:border-brand focus-within:ring-2 focus-within:ring-brand-soft">
        {value.map((t) => (
          <span key={t} className="inline-flex items-center gap-1 rounded-full bg-brand-soft py-1 pl-3 pr-1.5 text-sm font-medium text-brand">
            {t}
            <button
              type="button"
              onClick={() => onChange(value.filter((x) => x !== t))}
              className="rounded-full p-0.5 hover:bg-brand/15"
              aria-label={`Remove ${t}`}
            >
              <X className="h-3.5 w-3.5" aria-hidden />
            </button>
          </span>
        ))}
        <input
          id={id}
          value={draft}
          disabled={full}
          maxLength={maxLength}
          onChange={(e) => {
            const v = e.target.value;
            if (v.endsWith(",")) add(v.slice(0, -1));
            else setDraft(v);
          }}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              add(draft);
            } else if (e.key === "Backspace" && !draft && value.length) {
              onChange(value.slice(0, -1));
            }
          }}
          onBlur={() => draft && add(draft)}
          placeholder={full ? "Limit reached" : placeholder}
          className="min-w-[10rem] flex-1 bg-transparent px-1 py-1 text-sm outline-none placeholder:text-muted"
        />
      </div>
      {hint && <p className="mt-1 text-xs text-muted">{hint}</p>}
      {unused.length > 0 && !full && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {unused.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => add(s)}
              className="rounded-full border border-dashed border-border px-2.5 py-0.5 text-xs text-muted hover:border-brand hover:text-brand"
            >
              + {s}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
