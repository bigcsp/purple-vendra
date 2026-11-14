"use client";

import { Check, Share2 } from "lucide-react";
import { useState } from "react";

/** Shares the page with the phone's share sheet, or copies the link on desktop. */
export function ShareProfileButton({ path, name, light = false }: { path: string; name: string; light?: boolean }) {
  const [copied, setCopied] = useState(false);

  async function share() {
    const url = `${window.location.origin}${path}`;
    if (navigator.share) {
      try {
        await navigator.share({ title: `${name} on Purple Shop`, url });
        return;
      } catch (e) {
        if (e instanceof DOMException && e.name === "AbortError") return;
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      window.prompt("Copy this link:", url);
    }
  }

  return (
    <button
      type="button"
      onClick={share}
      className={`inline-flex items-center justify-center gap-2 rounded-xl border px-4 py-2.5 font-medium ${
        light ? "border-white/30 bg-white/10 text-white backdrop-blur hover:bg-white/20" : "border-border bg-card text-brand hover:bg-brand-soft"
      }`}
    >
      {copied ? <Check className="h-4 w-4" aria-hidden /> : <Share2 className="h-4 w-4" aria-hidden />}
      {copied ? "Link copied" : "Share"}
    </button>
  );
}
