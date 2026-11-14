"use client";

import { MessageCircle } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { startConversation } from "@/server/actions/messages";

/** "Message seller" — opens a private Purple Shop chat. */
export function MessageButton({
  sellerId,
  listingId,
  label = "Message seller",
  variant = "outline",
  className = "",
}: {
  sellerId: string;
  listingId?: string;
  label?: string;
  variant?: "outline" | "light" | "primary" | "outline-light";
  className?: string;
}) {
  const router = useRouter();
  const path = usePathname();
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const look =
    variant === "outline-light"
      ? "inline-flex w-full items-center justify-center gap-2 rounded-xl border border-white/30 bg-white/10 px-4 py-2.5 font-medium text-white backdrop-blur hover:bg-white/20"
      : variant === "primary"
      ? "inline-flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-5 py-2.5 font-medium text-white shadow-sm hover:bg-brand-deep"
      : variant === "light"
      ? "inline-flex items-center gap-1.5 rounded-full bg-white/15 px-4 py-1.5 text-sm font-medium text-white hover:bg-white/25"
      : "inline-flex w-full items-center justify-center gap-2 rounded-xl border border-brand px-4 py-2.5 font-medium text-brand hover:bg-brand-soft";

  return (
    <div className={className}>
      <button
        type="button"
        disabled={pending}
        onClick={() =>
          start(async () => {
            setError(null);
            const r = await startConversation(sellerId, listingId);
            if (r.signIn) return router.push(`/signup?reason=message&next=${encodeURIComponent(path)}`);
            if (r.error || !r.id) return setError(r.error ?? "Couldn't open the chat. Please try again.");
            router.push(`/messages/${r.id}`);
          })
        }
        className={`${look} disabled:opacity-60`}
      >
        <MessageCircle className="h-4 w-4" strokeWidth={2} aria-hidden />
        {pending ? "Opening chat…" : label}
      </button>
      {error && <p className={`mt-1 text-xs ${variant === "light" || variant === "outline-light" ? "text-white" : "text-red-700"}`}>{error}</p>}
    </div>
  );
}
