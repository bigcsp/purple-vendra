"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { setCartQuantity } from "@/server/actions/shop";

export function CartQuantity({ listingId, quantity }: { listingId: string; quantity: number }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const change = (q: number) =>
    start(async () => {
      await setCartQuantity(listingId, q);
      router.refresh();
    });

  return (
    <div className="flex items-center gap-1">
      <button disabled={pending} onClick={() => change(quantity - 1)} aria-label="One less"
        className="h-8 w-8 rounded-full border border-border text-brand">−</button>
      <span className="w-6 text-center text-sm">{quantity}</span>
      <button disabled={pending || quantity >= 99} onClick={() => change(quantity + 1)} aria-label="One more"
        className="h-8 w-8 rounded-full border border-border text-brand">+</button>
      <button disabled={pending} onClick={() => change(0)} className="ml-2 text-xs text-muted hover:text-red-600">Remove</button>
    </div>
  );
}
