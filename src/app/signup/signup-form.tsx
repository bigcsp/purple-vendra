"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { signUp, type FormState } from "@/app/actions/auth";
import { Field, Notice, buttonClass } from "@/components/ui";

type Intent = "shop" | "sell" | "both";

const CHOICES: { value: Intent; title: string; text: string; icon: string }[] = [
  { value: "shop", title: "I want to shop or hire", text: "Buy from makers, book pros and freelancers", icon: "🛍️" },
  { value: "sell", title: "I want to sell", text: "Open a shop for your products, skills or services", icon: "🏪" },
  { value: "both", title: "Both", text: "Shop on Purple Shop and run my own shop", icon: "✨" },
];

export function SignupForm({ next, initialIntent }: { next: string; initialIntent: Intent }) {
  const [state, action, pending] = useActionState<FormState, FormData>(signUp, {});
  const [intent, setIntent] = useState<Intent>(initialIntent);

  if (state.message) {
    return (
      <div className="space-y-3">
        <Notice tone="success">{state.message}</Notice>
        {intent !== "shop" && (
          <p className="text-sm text-muted">
            After you confirm, we&apos;ll walk you through opening your shop. It takes about 5 minutes.
          </p>
        )}
      </div>
    );
  }

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="next" value={next} />
      <input type="hidden" name="intent" value={intent} />
      <fieldset>
        <legend className="text-sm font-medium text-brand-strong">What brings you to Purple Shop?</legend>
        <div className="mt-2 grid gap-2">
          {CHOICES.map((c) => (
            <label
              key={c.value}
              className={`flex cursor-pointer items-center gap-3 rounded-2xl border p-3 transition ${
                intent === c.value ? "border-brand bg-brand-soft" : "border-border bg-card hover:border-brand/50"
              }`}
            >
              <input
                type="radio"
                name="intent_choice"
                value={c.value}
                checked={intent === c.value}
                onChange={() => setIntent(c.value)}
                className="sr-only"
              />
              <span className="text-2xl" aria-hidden>{c.icon}</span>
              <span>
                <span className="block text-sm font-semibold text-brand-strong">{c.title}</span>
                <span className="block text-xs text-muted">{c.text}</span>
              </span>
              <span className={`ml-auto h-4 w-4 shrink-0 rounded-full border-2 ${intent === c.value ? "border-brand bg-brand" : "border-border"}`} aria-hidden />
            </label>
          ))}
        </div>
      </fieldset>

      <Field label={intent === "shop" ? "Your name" : "Your name (you can add a business name later)"} name="display_name" required maxLength={80} autoComplete="name" />
      <Field
        label="Username"
        name="username"
        required
        pattern="[a-z0-9_]{3,30}"
        hint={intent === "shop" ? "Lowercase letters, numbers and _" : "Lowercase letters, numbers and _. It becomes your shop link: /shop/username"}
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
      <p className="text-xs text-muted">
        By creating an account you agree to how we handle your data, explained in our{" "}
        <Link href="/privacy" className="text-brand underline">privacy policy</Link>.
      </p>
      <button className={buttonClass} disabled={pending}>
        {pending ? "Creating account…" : intent === "shop" ? "Create free account" : "Create account and start my shop"}
      </button>
      <p className="text-center text-sm text-muted">
        Already have an account?{" "}
        <Link href={next ? `/login?next=${encodeURIComponent(next)}` : "/login"} className="font-medium text-brand">
          Sign in
        </Link>
        {" · "}
        <Link href="/" className="font-medium text-brand">Just browsing</Link>
      </p>
    </form>
  );
}
