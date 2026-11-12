"use client";

import { CirclePlay, History, LayoutGrid, Search, ShoppingBag, TrendingUp, type LucideIcon } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import type { Suggestion } from "@/server/api/suggest";

const RECENT_KEY = "ps-recent-searches";
const MAX_RECENT = 6;
/** Shown when there aren't enough real popular searches yet. */
const STARTERS = ["Aso ebi", "Ankara", "Logo design", "Makeup artist", "Plumber", "Photographer", "Website", "Cakes"];

const GROUPS: Record<Suggestion["kind"], string> = {
  search: "Searches",
  category: "Categories",
  shop: "Shops",
  listing: "Products & services",
  story: "Stories",
};

type Option = { id: string; label: string; detail?: string | null; href: string; image?: string | null; kind: string; verified?: boolean; recent?: boolean };

function readRecent(): string[] {
  try {
    const v = JSON.parse(localStorage.getItem(RECENT_KEY) ?? "[]");
    return Array.isArray(v) ? v.filter((x) => typeof x === "string").slice(0, MAX_RECENT) : [];
  } catch {
    return [];
  }
}

function saveRecent(q: string) {
  try {
    const next = [q, ...readRecent().filter((x) => x.toLowerCase() !== q.toLowerCase())].slice(0, MAX_RECENT);
    localStorage.setItem(RECENT_KEY, JSON.stringify(next));
  } catch {
    /* private mode: fine */
  }
}

/**
 * The one search box: products, services, shops, stories and categories,
 * with suggestions as you type. Works as a plain form without JavaScript.
 */
export function SearchBox({
  variant = "header",
  defaultValue = "",
  placeholder = "Search adire, logo design, plumber…",
}: {
  variant?: "header" | "hero";
  defaultValue?: string;
  placeholder?: string;
}) {
  const router = useRouter();
  const listId = useId();
  const wrap = useRef<HTMLFormElement>(null);
  const [value, setValue] = useState(defaultValue);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const [items, setItems] = useState<Suggestion[]>([]);
  const [loading, setLoading] = useState(false);
  const [recent, setRecent] = useState<string[]>([]);
  const [popular, setPopular] = useState<string[] | null>(null);

  const q = value.trim();

  // Suggestions while typing (debounced, older requests cancelled).
  useEffect(() => {
    if (q.length < 2) return;
    const ctrl = new AbortController();
    const t = window.setTimeout(async () => {
      setLoading(true);
      try {
        const r = await fetch(`/api/suggest?q=${encodeURIComponent(q)}`, { signal: ctrl.signal });
        const json = (await r.json()) as { items?: Suggestion[] };
        setItems(json.items ?? []);
      } catch {
        /* aborted or offline: keep the last list */
      } finally {
        if (!ctrl.signal.aborted) setLoading(false);
      }
    }, 180);
    return () => {
      window.clearTimeout(t);
      ctrl.abort();
    };
  }, [q]);

  // Close when clicking elsewhere.
  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, []);

  function onFocus() {
    setRecent(readRecent());
    setOpen(true);
    if (popular === null) {
      setPopular([]);
      fetch("/api/suggest?popular=1")
        .then((r) => r.json())
        .then((j: { popular?: string[] }) => setPopular(j.popular ?? []))
        .catch(() => setPopular([]));
    }
  }

  const options: Option[] = useMemo(() => {
    if (q.length >= 2) {
      const searchFor: Option = { id: "go", kind: "go", label: `Search for “${q}”`, href: `/search?q=${encodeURIComponent(q)}` };
      return [
        searchFor,
        ...items
          .filter((s) => !(s.kind === "search" && s.label.toLowerCase() === q.toLowerCase()))
          .map((s, i) => ({ id: `s${i}`, ...s })),
      ];
    }
    const pop = [...(popular ?? []), ...STARTERS.filter((s) => !(popular ?? []).some((p) => p.toLowerCase() === s.toLowerCase()))].slice(0, 8);
    return [
      ...recent.map((r, i) => ({ id: `r${i}`, kind: "recent", label: r, href: `/search?q=${encodeURIComponent(r)}`, recent: true })),
      ...pop
        .filter((p) => !recent.some((r) => r.toLowerCase() === p.toLowerCase()))
        .map((p, i) => ({ id: `p${i}`, kind: "popular", label: p, href: `/search?q=${encodeURIComponent(p)}` })),
    ];
  }, [q, items, recent, popular]);

  function go(o: Option) {
    const searched = o.kind === "go" ? q : o.kind === "search" || o.kind === "recent" || o.kind === "popular" ? o.label : null;
    if (searched) saveRecent(searched);
    setOpen(false);
    router.push(o.href);
  }

  function submit(e: React.FormEvent) {
    e.preventDefault();
    if (open && active >= 0 && options[active]) return go(options[active]);
    if (!q) return;
    saveRecent(q);
    setOpen(false);
    router.push(`/search?q=${encodeURIComponent(q)}`);
  }

  function onKey(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
      setActive((a) => (options.length ? (a + 1) % options.length : -1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((a) => (options.length ? (a <= 0 ? options.length - 1 : a - 1) : -1));
    } else if (e.key === "Escape") {
      setOpen(false);
      setActive(-1);
    }
  }

  function clearRecent() {
    try {
      localStorage.removeItem(RECENT_KEY);
    } catch {
      /* ignore */
    }
    setRecent([]);
  }

  const hero = variant === "hero";
  const showList = open && options.length > 0;
  let lastGroup = "";

  return (
    <form ref={wrap} action="/search" role="search" onSubmit={submit} className="relative w-full">
      <label className="relative block">
        <span className="sr-only">Search Purple Shop</span>
        <svg viewBox="0 0 24 24" aria-hidden fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"
          className={`pointer-events-none absolute top-1/2 -translate-y-1/2 text-muted ${hero ? "left-5 h-5 w-5" : "left-3.5 h-4 w-4"}`}>
          <circle cx="11" cy="11" r="7" />
          <path d="m20 20-3.5-3.5" />
        </svg>
        <input
          type="search"
          name="q"
          value={value}
          onChange={(e) => {
            setValue(e.target.value);
            setActive(-1);
            setOpen(true);
            if (e.target.value.trim().length < 2) setItems([]);
          }}
          onFocus={onFocus}
          onKeyDown={onKey}
          placeholder={placeholder}
          autoComplete="off"
          enterKeyHint="search"
          role="combobox"
          aria-expanded={showList}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={active >= 0 && options[active] ? `${listId}-${options[active].id}` : undefined}
          className={
            hero
              ? "w-full rounded-full border-0 bg-white py-4 pl-13 pr-28 text-base sm:pr-32 text-[#1a1024] shadow-xl outline-none ring-brand/40 placeholder:text-[#6b6478] focus:ring-4"
              : "w-full rounded-full border border-border bg-card py-2 pl-10 pr-4 text-sm outline-none transition focus:border-brand focus:ring-2 focus:ring-brand-soft"
          }
        />
        {hero && (
          <button className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-brand px-5 py-2.5 sm:px-6 font-medium text-white hover:bg-brand-deep">
            Search
          </button>
        )}
      </label>

      {showList && (
        <ul
          id={listId}
          role="listbox"
          aria-label="Search suggestions"
          className="absolute inset-x-0 top-full z-50 mt-2 max-h-[70vh] overflow-y-auto rounded-2xl border border-border bg-card p-1.5 text-left text-sm text-foreground shadow-2xl"
        >
          {options.map((o, i) => {
            const group =
              o.kind === "recent" ? "Recent searches" : o.kind === "popular" ? "Popular on Purple Shop" : o.kind === "go" ? "" : GROUPS[o.kind as Suggestion["kind"]];
            const heading = group && group !== lastGroup ? group : null;
            lastGroup = group || lastGroup;
            return (
              <li key={o.id} role="presentation">
                {heading && (
                  <div className="flex items-center justify-between px-3 pb-1 pt-2.5 text-xs font-semibold text-muted">
                    <span>{heading}</span>
                    {o.kind === "recent" && (
                      <button type="button" onMouseDown={(e) => e.preventDefault()} onClick={clearRecent} className="font-normal underline hover:text-brand">
                        Clear
                      </button>
                    )}
                  </div>
                )}
                <div
                  id={`${listId}-${o.id}`}
                  role="option"
                  aria-selected={i === active}
                  onMouseDown={(e) => e.preventDefault()}
                  onMouseEnter={() => setActive(i)}
                  onClick={() => go(o)}
                  className={`flex cursor-pointer items-center gap-3 rounded-xl px-3 py-1.5 ${i === active ? "bg-brand-soft" : ""}`}
                >
                  <Thumb o={o} />
                  <span className="min-w-0 flex-1">
                    <span className={`block truncate ${o.kind === "go" ? "font-medium text-brand" : ""}`}>
                      {o.label}
                      {o.verified && <span className="ml-1 text-green-700" title="ID verified">✓</span>}
                    </span>
                    {o.detail && <span className="block truncate text-xs text-muted">{o.detail}</span>}
                  </span>
                </div>
              </li>
            );
          })}
          {loading && q.length >= 2 && items.length === 0 && (
            <li role="presentation" className="px-3 py-2 text-xs text-muted">Looking…</li>
          )}
        </ul>
      )}
    </form>
  );
}

function Thumb({ o }: { o: Option }) {
  const compact = ["go", "search", "recent", "popular", "category"].includes(o.kind);
  const box = `flex shrink-0 items-center justify-center overflow-hidden bg-brand-soft text-brand ${compact ? "h-7 w-7 text-xs" : "h-9 w-9"}`;
  if (o.image)
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={o.image} alt="" loading="lazy" className={`h-9 w-9 shrink-0 object-cover ${o.kind === "shop" ? "rounded-full" : "rounded-lg"}`} />;
  const icons: Record<string, LucideIcon> = {
    go: Search, search: Search, recent: History, popular: TrendingUp, category: LayoutGrid, listing: ShoppingBag, story: CirclePlay,
  };
  const Icon = icons[o.kind] ?? Search;
  return (
    <span className={`${box} ${o.kind === "shop" ? "rounded-full" : "rounded-lg"}`} aria-hidden>
      {o.kind === "shop" ? o.label.slice(0, 1).toUpperCase() : <Icon className={compact ? "h-3.5 w-3.5" : "h-4 w-4"} strokeWidth={2} />}
    </span>
  );
}
