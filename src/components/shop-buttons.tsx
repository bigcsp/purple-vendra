"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { addToCart, toggleFollow } from "@/app/actions/shop";

export function AddToCartButton({ listingId, className = "" }: { listingId: string; className?: string }) {
  const router = useRouter();
  const path = usePathname();
  const [state, setState] = useState<"idle" | "added" | string>("idle");
  const [pending, start] = useTransition();

  if (state === "added") {
    return (
      <Link href="/cart" className={`inline-flex items-center justify-center rounded-xl bg-green-600 px-4 py-2.5 font-medium text-white ${className}`}>
        ✓ In your cart · View cart
      </Link>
    );
  }
  return (
    <div className={className}>
      <button
        disabled={pending}
        onClick={() =>
          start(async () => {
            const r = await addToCart(listingId);
            if (r.signIn) return router.push(`/signup?reason=cart&next=${encodeURIComponent(path)}`);
            setState(r.error ?? "added");
          })
        }
        className="inline-flex w-full items-center justify-center rounded-xl bg-brand px-4 py-2.5 font-medium text-white hover:bg-brand-deep disabled:opacity-60"
      >
        {pending ? "Adding…" : "Add to cart"}
      </button>
      {state !== "idle" && <p className="mt-1 text-xs text-red-700">{state}</p>}
    </div>
  );
}

export function FollowButton({
  sellerId,
  initialFollowing,
  initialCount,
  isSelf,
  compact = false,
}: {
  sellerId: string;
  initialFollowing: boolean;
  initialCount: number;
  isSelf: boolean;
  compact?: boolean;
}) {
  const router = useRouter();
  const path = usePathname();
  const [following, setFollowing] = useState(initialFollowing);
  const [count, setCount] = useState(initialCount);
  const [pending, start] = useTransition();

  if (isSelf) return compact ? null : <span className="text-sm text-muted">{count} followers</span>;

  return (
    <button
      disabled={pending}
      onClick={() =>
        start(async () => {
          const next = !following;
          const r = await toggleFollow(sellerId, next);
          if (r.signIn) return router.push(`/signup?reason=follow&next=${encodeURIComponent(path)}`);
          if (r.ok) {
            setFollowing(next);
            setCount((c) => c + (next ? 1 : -1));
          }
        })
      }
      className={`rounded-full px-4 py-1.5 text-sm font-medium transition ${
        following ? "border border-border bg-card text-brand" : "bg-accent text-brand-strong hover:brightness-95"
      }`}
    >
      {following ? "Following" : "Follow"}
      {!compact && <span className="ml-1.5 opacity-70">· {count}</span>}
    </button>
  );
}
