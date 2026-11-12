"use client";

import { usePathname, useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toggleSaved, useSaved } from "@/lib/saved-store";

function Heart({ filled, className }: { filled: boolean; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className={className} fill={filled ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" strokeLinejoin="round">
      <path d="M12 20.5s-7.5-4.6-9.3-9.1C1.4 8 3.6 4.5 7.2 4.5c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3.6 0 5.8 3.5 4.5 6.9-1.8 4.5-9.3 9.1-9.3 9.1Z" />
    </svg>
  );
}

function useToggle(listingId: string) {
  const router = useRouter();
  const path = usePathname();
  const { ids } = useSaved();
  const saved = ids.has(listingId);
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const toggle = () =>
    start(async () => {
      setError(null);
      const r = await toggleSaved(listingId);
      if (r === "signin") router.push(`/signup?reason=save&next=${encodeURIComponent(path)}`);
      else if (r !== "ok") setError(r);
    });

  return { saved, toggle, pending, error };
}

/** Small heart in the corner of a listing card. */
export function SaveHeart({ listingId, title }: { listingId: string; title: string }) {
  const { saved, toggle, pending } = useToggle(listingId);
  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      aria-pressed={saved}
      aria-label={saved ? `Remove ${title} from saved` : `Save ${title}`}
      title={saved ? "Saved" : "Save"}
      className={`absolute right-2 top-2 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-white/90 shadow-md backdrop-blur transition hover:scale-105 ${
        saved ? "text-[#e0245e]" : "text-[#3b0f6e]"
      }`}
    >
      <Heart filled={saved} className="h-5 w-5" />
    </button>
  );
}

/** Full "Save" button for the listing page. */
export function SaveButton({ listingId }: { listingId: string }) {
  const { saved, toggle, pending, error } = useToggle(listingId);
  return (
    <div>
      <button
        type="button"
        onClick={toggle}
        disabled={pending}
        aria-pressed={saved}
        className={`inline-flex w-full items-center justify-center gap-2 rounded-xl border px-4 py-2.5 font-medium transition ${
          saved ? "border-[#e0245e]/40 bg-[#e0245e]/10 text-[#e0245e]" : "border-border text-brand hover:bg-brand-soft"
        }`}
      >
        <Heart filled={saved} className="h-5 w-5" />
        {saved ? "Saved" : "Save for later"}
      </button>
      {error && <p className="mt-1 text-xs text-red-700">{error}</p>}
    </div>
  );
}
