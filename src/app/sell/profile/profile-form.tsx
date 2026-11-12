"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import {
  addServiceArea,
  removeServiceArea,
  saveWorkingHours,
  setLogo,
  updateProfile,
  type HoursRow,
  type ProfileInput,
} from "@/app/actions/profile";
import { Card, Notice, buttonClass } from "@/components/ui";
import { DAYS, NIGERIAN_STATES } from "@/lib/nigeria";
import { uploadProfileLogo } from "@/lib/upload";

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

type Area = { state: string; city: string };

export function ProfileForm({
  userId,
  initial,
  logoUrl,
  hours,
  areas,
}: {
  userId: string;
  initial: ProfileInput;
  logoUrl: string | null;
  hours: HoursRow[];
  areas: Area[];
}) {
  return (
    <div className="space-y-6">
      <DetailsCard userId={userId} initial={initial} logoUrl={logoUrl} />
      <HoursCard initial={hours} />
      <AreasCard initial={areas} />
    </div>
  );
}

function DetailsCard({ userId, initial, logoUrl }: { userId: string; initial: ProfileInput; logoUrl: string | null }) {
  const router = useRouter();
  const [v, setV] = useState(initial);
  const [logo, setLogoUrl] = useState(logoUrl);
  const [msg, setMsg] = useState<{ tone: "error" | "success"; text: string }>();
  const [pending, start] = useTransition();
  const [uploading, setUploading] = useState(false);
  const set = <K extends keyof ProfileInput>(k: K, val: ProfileInput[K]) => setV((x) => ({ ...x, [k]: val }));

  async function onLogo(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setMsg(undefined);
    setUploading(true);
    try {
      const path = await uploadProfileLogo(file, userId);
      const r = await setLogo(path);
      if (r.error) throw new Error(r.error);
      setLogoUrl(URL.createObjectURL(file));
      router.refresh();
    } catch (err) {
      setMsg({ tone: "error", text: err instanceof Error ? err.message : "Upload failed." });
    } finally {
      setUploading(false);
    }
  }

  return (
    <Card>
      <h2 className="text-lg font-semibold text-brand-strong">Shop details</h2>
      <div className="mt-4 flex items-center gap-4">
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} alt="" className="h-20 w-20 rounded-full object-cover ring-2 ring-brand-soft" />
        ) : (
          <span className="flex h-20 w-20 items-center justify-center rounded-full bg-brand-soft text-2xl font-bold text-brand">
            {(v.businessName || "?").slice(0, 1).toUpperCase()}
          </span>
        )}
        <label className="cursor-pointer rounded-xl border border-border px-4 py-2 text-sm font-medium text-brand hover:bg-brand-soft">
          {uploading ? "Uploading…" : logo ? "Change logo or photo" : "Add logo or photo"}
          <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={onLogo} disabled={uploading} />
        </label>
      </div>

      <form
        className="mt-5 space-y-4"
        onSubmit={(e) => {
          e.preventDefault();
          setMsg(undefined);
          start(async () => {
            const r = await updateProfile(v);
            setMsg(r.error ? { tone: "error", text: r.error } : { tone: "success", text: "Saved. Your shop page is updated." });
            if (!r.error) router.refresh();
          });
        }}
      >
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Business name</span>
          <input className={inputClass} value={v.businessName} maxLength={80} onChange={(e) => set("businessName", e.target.value)}
            placeholder="SOSE Enterprise" />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Headline <span className="font-normal text-muted">({v.headline.length}/80)</span></span>
          <input className={inputClass} value={v.headline} maxLength={80} onChange={(e) => set("headline", e.target.value)}
            placeholder="Handmade Adire and Ankara for every occasion" />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">About your business <span className="font-normal text-muted">({v.bio.length}/500)</span></span>
          <textarea className={inputClass} rows={4} value={v.bio} maxLength={500} onChange={(e) => set("bio", e.target.value)}
            placeholder="What you make or do, how long it takes, what makes you different" />
        </label>
        <div className="grid gap-4 sm:grid-cols-3">
          <label className="block">
            <span className="text-sm font-medium text-brand-strong">State</span>
            <select className={inputClass} value={v.state} onChange={(e) => set("state", e.target.value)}>
              <option value="">Choose…</option>
              {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-medium text-brand-strong">City or area</span>
            <input className={inputClass} value={v.city} maxLength={80} onChange={(e) => set("city", e.target.value)} placeholder="Abeokuta" />
          </label>
          <label className="block">
            <span className="text-sm font-medium text-brand-strong">Years of experience</span>
            <input className={inputClass} inputMode="numeric" value={v.yearsExperience} onChange={(e) => set("yearsExperience", e.target.value)} placeholder="5" />
          </label>
        </div>
        <label className="flex items-center gap-3 rounded-xl border border-border bg-card p-3">
          <input type="checkbox" checked={v.isAvailable} onChange={(e) => set("isAvailable", e.target.checked)} className="h-5 w-5 accent-[var(--brand)]" />
          <span>
            <span className="block text-sm font-medium">Taking new orders and bookings</span>
            <span className="block text-xs text-muted">Turn off when you&apos;re fully booked or away. Buyers will see &quot;Not taking orders right now&quot;.</span>
          </span>
        </label>
        {msg && <Notice tone={msg.tone}>{msg.text}</Notice>}
        <button className={`${buttonClass} sm:w-auto`} disabled={pending}>{pending ? "Saving…" : "Save shop details"}</button>
        <p className="text-xs text-muted">Don&apos;t add phone numbers, WhatsApp or bank details. Buyers contact and pay you safely through Purple Shop.</p>
      </form>
    </Card>
  );
}

function HoursCard({ initial }: { initial: HoursRow[] }) {
  const router = useRouter();
  const [rows, setRows] = useState(() =>
    DAYS.map((_, day) => {
      const r = initial.find((h) => h.day === day);
      return { day, open: !!r, opens: r?.opens ?? "09:00", closes: r?.closes ?? "18:00" };
    }),
  );
  const [msg, setMsg] = useState<{ tone: "error" | "success"; text: string }>();
  const [pending, start] = useTransition();
  const update = (day: number, patch: Partial<(typeof rows)[number]>) =>
    setRows((rs) => rs.map((r) => (r.day === day ? { ...r, ...patch } : r)));

  return (
    <Card>
      <h2 className="text-lg font-semibold text-brand-strong">Working hours</h2>
      <p className="mt-1 text-sm text-muted">Shown on your shop page so buyers know when you respond.</p>
      <ul className="mt-4 space-y-2">
        {rows.map((r) => (
          <li key={r.day} className="flex flex-wrap items-center gap-3 text-sm">
            <label className="flex w-32 items-center gap-2">
              <input type="checkbox" checked={r.open} onChange={(e) => update(r.day, { open: e.target.checked })} className="accent-[var(--brand)]" />
              {DAYS[r.day]}
            </label>
            {r.open ? (
              <>
                <input type="time" value={r.opens} onChange={(e) => update(r.day, { opens: e.target.value })}
                  className="rounded-lg border border-border px-2 py-1" aria-label={`${DAYS[r.day]} opens`} />
                <span className="text-muted">to</span>
                <input type="time" value={r.closes} onChange={(e) => update(r.day, { closes: e.target.value })}
                  className="rounded-lg border border-border px-2 py-1" aria-label={`${DAYS[r.day]} closes`} />
              </>
            ) : (
              <span className="text-muted">Closed</span>
            )}
          </li>
        ))}
      </ul>
      {msg && <div className="mt-3"><Notice tone={msg.tone}>{msg.text}</Notice></div>}
      <button
        disabled={pending}
        onClick={() =>
          start(async () => {
            setMsg(undefined);
            const r = await saveWorkingHours(rows.filter((x) => x.open).map(({ day, opens, closes }) => ({ day, opens, closes })));
            setMsg(r.error ? { tone: "error", text: r.error } : { tone: "success", text: "Working hours saved." });
            if (!r.error) router.refresh();
          })
        }
        className={`${buttonClass} mt-4 sm:w-auto`}
      >
        {pending ? "Saving…" : "Save working hours"}
      </button>
    </Card>
  );
}

function AreasCard({ initial }: { initial: Area[] }) {
  const router = useRouter();
  const [state, setState] = useState("");
  const [city, setCity] = useState("");
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();

  return (
    <Card>
      <h2 className="text-lg font-semibold text-brand-strong">Where you deliver or work</h2>
      <p className="mt-1 text-sm text-muted">Buyers who filter search by state will find you here too.</p>
      {initial.length > 0 && (
        <ul className="mt-3 flex flex-wrap gap-2">
          {initial.map((a) => (
            <li key={`${a.state}-${a.city}`} className="flex items-center gap-1 rounded-full bg-brand-soft px-3 py-1 text-sm text-brand">
              {a.city === "All areas" ? `All of ${a.state}` : `${a.city}, ${a.state}`}
              <button
                aria-label={`Remove ${a.city}, ${a.state}`}
                disabled={pending}
                onClick={() =>
                  start(async () => {
                    const r = await removeServiceArea(a.state, a.city);
                    if (r.error) setError(r.error);
                    else router.refresh();
                  })
                }
                className="ml-1 text-xs hover:text-red-600"
              >
                ✕
              </button>
            </li>
          ))}
        </ul>
      )}
      <form
        className="mt-4 flex flex-wrap items-end gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          setError(undefined);
          start(async () => {
            const r = await addServiceArea(state, city);
            if (r.error) return setError(r.error);
            setCity("");
            router.refresh();
          });
        }}
      >
        <select value={state} onChange={(e) => setState(e.target.value)} className="rounded-xl border border-border bg-card px-3 py-2 text-sm" aria-label="State">
          <option value="">State…</option>
          {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <input value={city} onChange={(e) => setCity(e.target.value)} maxLength={80} placeholder="Area (optional, e.g. Lekki)"
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm" aria-label="City or area" />
        <button disabled={pending || !state} className="rounded-xl bg-brand px-4 py-2 text-sm font-medium text-white disabled:opacity-50">
          Add area
        </button>
      </form>
      {error && <div className="mt-3"><Notice tone="error">{error}</Notice></div>}
    </Card>
  );
}
