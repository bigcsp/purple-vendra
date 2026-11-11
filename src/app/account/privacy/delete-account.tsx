"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { cancelAccountDeletion, requestAccountDeletion } from "@/app/actions/privacy";
import { Notice } from "@/components/ui";

const fmt = (d: Date) => d.toLocaleDateString("en-NG", { day: "numeric", month: "long", year: "numeric" });

export function DeleteAccount({
  username,
  requestedAt,
  has2fa,
  confirmed2fa,
}: {
  username: string;
  requestedAt: string | null;
  has2fa: boolean;
  confirmed2fa: boolean;
}) {
  const router = useRouter();
  const [typed, setTyped] = useState("");
  const [error, setError] = useState<string>();
  const [pending, start] = useTransition();

  if (requestedAt) {
    const on = new Date(new Date(requestedAt).getTime() + 30 * 86400000);
    return (
      <div className="mt-2 space-y-3">
        <Notice tone="error">Your account will be deleted on {fmt(on)}. Until then you can still cancel.</Notice>
        {error && <Notice tone="error">{error}</Notice>}
        <button
          disabled={pending}
          onClick={() =>
            start(async () => {
              const r = await cancelAccountDeletion();
              if (r.error) setError(r.error);
              else router.refresh();
            })
          }
          className="rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-deep disabled:opacity-60"
        >
          {pending ? "Cancelling…" : "Cancel deletion and keep my account"}
        </button>
      </div>
    );
  }

  return (
    <div className="mt-2 space-y-3 text-sm">
      <p className="text-muted">
        After you ask, you have <strong>30 days</strong> to change your mind. Then we delete your profile, listings,
        stories, likes, comments, saved items and messages. If you&apos;ve bought or sold through Purple Vendra, we keep
        an anonymous record of those payments because the law requires it, but it won&apos;t be linked to you.
      </p>
      <p className="text-muted">You can&apos;t delete your account while an order or booking is still in progress.</p>
      {has2fa && !confirmed2fa ? (
        <Notice tone="error">
          Sign in again with your authenticator code first.{" "}
          <Link href="/login/verify?next=/account/privacy" className="underline">Enter code</Link>
        </Notice>
      ) : (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setError(undefined);
            start(async () => {
              const r = await requestAccountDeletion(typed);
              if (r.error) setError(r.error);
              else router.refresh();
            });
          }}
          className="space-y-3"
        >
          <label className="block">
            <span className="font-medium">Type your username <strong>{username}</strong> to confirm</span>
            <input
              value={typed}
              onChange={(e) => setTyped(e.target.value)}
              autoComplete="off"
              className="mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-red-400"
            />
          </label>
          {error && <Notice tone="error">{error}</Notice>}
          <button
            disabled={pending || typed.trim().toLowerCase() !== username.toLowerCase()}
            className="rounded-xl bg-[#dc2626] px-4 py-2.5 font-medium text-white hover:bg-[#b91c1c] disabled:opacity-50"
          >
            {pending ? "Sending…" : "Delete my account"}
          </button>
        </form>
      )}
    </div>
  );
}
