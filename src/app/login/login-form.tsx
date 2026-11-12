"use client";

import Link from "next/link";
import { useActionState } from "react";
import { signIn, type FormState } from "@/server/actions/auth";
import { Field, Notice, buttonClass } from "@/components/ui";

export function LoginForm({ next, linkError, confirmed = false }: { next: string; linkError: boolean; confirmed?: boolean }) {
  const [state, action, pending] = useActionState<FormState, FormData>(signIn, {});

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="next" value={next} />
      {confirmed && !state.error && (
        <Notice tone="success">Your email is confirmed. Sign in to continue.</Notice>
      )}
      {linkError && !state.error && (
        <Notice tone="error">That link has expired or was already used. Sign in, or sign up again.</Notice>
      )}
      <Field label="Email" name="email" type="email" required autoComplete="email" />
      <Field label="Password" name="password" type="password" required autoComplete="current-password" />
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <button className={buttonClass} disabled={pending}>
        {pending ? "Signing in…" : "Sign in"}
      </button>
      <p className="text-center text-sm text-muted">
        New here?{" "}
        <Link href={next && next !== "/account" ? `/signup?next=${encodeURIComponent(next)}` : "/signup"} className="font-medium text-brand">
          Create an account
        </Link>
      </p>
    </form>
  );
}
