"use client";

import Link from "next/link";
import { useEffect, useSyncExternalStore } from "react";
import { formatNaira } from "@/lib/money";

/**
 * "Recently viewed" lives only on this phone or computer (localStorage),
 * so it works without an account and nobody else can see it.
 */
const KEY = "ps-recently-viewed";
const MAX = 12;

export type ViewedItem = {
  id: string;
  title: string;
  priceKobo: number;
  priceIsStarting: boolean;
  image: string | null;
  seller: string | null;
  at: number;
};

const listeners = new Set<() => void>();
let cache: { raw: string | null; items: ViewedItem[] } = { raw: null, items: [] };
const EMPTY: ViewedItem[] = [];

function read(): ViewedItem[] {
  let raw: string | null = null;
  try {
    raw = localStorage.getItem(KEY);
  } catch {
    return EMPTY;
  }
  if (raw === cache.raw) return cache.items;
  let items: ViewedItem[] = [];
  try {
    const parsed = JSON.parse(raw ?? "[]");
    if (Array.isArray(parsed)) items = parsed.filter((x) => x && typeof x.id === "string" && typeof x.title === "string").slice(0, MAX);
  } catch {
    items = [];
  }
  cache = { raw, items };
  return items;
}

function write(items: ViewedItem[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(items.slice(0, MAX)));
  } catch {
    /* private mode */
  }
  listeners.forEach((l) => l());
}

function subscribe(cb: () => void) {
  listeners.add(cb);
  const onStorage = (e: StorageEvent) => e.key === KEY && cb();
  window.addEventListener("storage", onStorage);
  return () => {
    listeners.delete(cb);
    window.removeEventListener("storage", onStorage);
  };
}

function useViewed() {
  return useSyncExternalStore(subscribe, read, () => EMPTY);
}

/** Put this on a listing page to remember the visit. Renders nothing. */
export function RememberView({ item }: { item: Omit<ViewedItem, "at"> }) {
  useEffect(() => {
    write([{ ...item, at: Date.now() }, ...read().filter((x) => x.id !== item.id)]);
    // Only when the listing changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [item.id]);
  return null;
}

/** Horizontal row of recently viewed listings. Hidden when empty. */
export function RecentlyViewed({ excludeId, title = "Recently viewed" }: { excludeId?: string; title?: string }) {
  const items = useViewed().filter((x) => x.id !== excludeId);
  if (items.length === 0) return null;

  return (
    <section aria-label={title}>
      <div className="mb-3 flex items-baseline justify-between gap-3">
        <h2 className="text-xl font-bold text-brand-strong">{title}</h2>
        <button type="button" onClick={() => write([])} className="text-sm text-muted underline hover:text-brand">
          Clear
        </button>
      </div>
      <ul className="-mx-5 flex gap-3 overflow-x-auto px-5 pb-2">
        {items.map((x) => (
          <li key={x.id} className="w-36 shrink-0 sm:w-44">
            <Link href={`/l/${x.id}`} className="block overflow-hidden rounded-2xl border border-border bg-card hover:border-brand">
              {x.image ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={x.image} alt="" loading="lazy" className="aspect-square w-full object-cover" />
              ) : (
                <div className="aspect-square bg-brand-soft" />
              )}
              <div className="p-2.5">
                <p className="line-clamp-2 text-sm">{x.title}</p>
                <p className="mt-0.5 text-sm text-brand-strong">
                  {x.priceIsStarting && <span className="text-muted">From </span>}
                  {formatNaira(x.priceKobo)}
                </p>
              </div>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
