import type { InputHTMLAttributes, ReactNode } from "react";

export function Card({ children }: { children: ReactNode }) {
  return <div className="rounded-3xl border border-border bg-card p-6 sm:p-8">{children}</div>;
}

export function Field({
  label,
  hint,
  ...input
}: { label: string; hint?: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="block">
      <span className="text-sm font-medium text-brand-strong">{label}</span>
      <input
        {...input}
        className="mt-1 block w-full rounded-xl border border-border bg-white px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft"
      />
      {hint && <span className="mt-1 block text-xs text-muted">{hint}</span>}
    </label>
  );
}

export const buttonClass =
  "inline-flex w-full items-center justify-center rounded-xl bg-brand px-4 py-2.5 font-medium text-white transition hover:bg-brand-strong disabled:opacity-60";

export function Notice({ tone, children }: { tone: "error" | "success"; children: ReactNode }) {
  const cls =
    tone === "error"
      ? "border-red-200 bg-red-50 text-red-700"
      : "border-green-200 bg-green-50 text-green-800";
  return <p className={`rounded-xl border p-3 text-sm ${cls}`}>{children}</p>;
}
