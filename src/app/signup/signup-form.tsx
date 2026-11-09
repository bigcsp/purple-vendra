"use client";

import Link from "next/link";
import { useActionState } from "react";
import { signUp, type FormState } from "@/app/actions/auth";
import { Field, Notice, buttonClass } from "@/components/ui";

export function SignupForm() {
  const [state, action, pending] = useActionState<FormState, FormData>(signUp, {});

  if (state.message) return <Notice tone="success">{state.message}</Notice>;

  return (
    <form action={action} className="space-y-4">
      <Field label="Your name" name="display_name" required maxLength={80} autoComplete="name" />
      <Field
        label="Username"
        name="username"
        required
        pattern="[a-z0-9_]{3,30}"
        hint="Lowercase letters, numbers and _ (this becomes your shop link)"
        autoComplete="username"
      />
      <Field label="Email" name="email" type="email" required autoComplete="email" />
      <Field
        label="Password"
        name="password"
        type="password"
        required
        minLength={8}
        hint="At least 8 characters"
        autoComplete="new-password"
      />
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <button className={buttonClass} disabled={pending}>
        {pending ? "Creating account…" : "Create account"}
      </button>
      <p className="text-center text-sm text-muted">
        Already have an account?{" "}
        <Link href="/login" className="font-medium text-brand">
          Sign in
        </Link>
      </p>
    </form>
  );
}
