"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { signOut } from "@/app/actions/auth";
import { createClient } from "@/lib/supabase/client";
import { Field, Notice, buttonClass } from "@/components/ui";

/** Asks for the 6-digit code from the authenticator app (raises the session to aal2). */
export function VerifyForm({ next }: { next: string }) {
  const router = useRouter();
  const [error, setError] = useState<string>();
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setPending(true);
    setError(undefined);

    const code = String(new FormData(e.currentTarget).get("code") ?? "").replace(/\s/g, "");
    const supabase = createClient();
    const { data: factors, error: listError } = await supabase.auth.mfa.listFactors();
    const totp = factors?.totp.find((f) => f.status === "verified");

    if (listError || !totp) {
      setPending(false);
      setError("We couldn't find your authenticator. Sign out and sign in again.");
      return;
    }

    const { error } = await supabase.auth.mfa.challengeAndVerify({ factorId: totp.id, code });
    if (error) {
      setPending(false);
      setError("That code didn't work. Check the time on your phone and try the newest code.");
      return;
    }

    router.replace(next);
    router.refresh();
  }

  return (
    <div className="space-y-4">
      <form onSubmit={onSubmit} className="space-y-4">
        <Field
          label="6-digit code"
          name="code"
          inputMode="numeric"
          autoComplete="one-time-code"
          pattern="[0-9 ]{6,7}"
          maxLength={7}
          required
          autoFocus
        />
        {error && <Notice tone="error">{error}</Notice>}
        <button className={buttonClass} disabled={pending}>
          {pending ? "Checking…" : "Confirm"}
        </button>
      </form>
      <form action={signOut}>
        <button className="w-full text-center text-sm text-muted hover:text-brand">
          Not you? Sign out
        </button>
      </form>
    </div>
  );
}
