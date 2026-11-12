"use client";

import { useActionState } from "react";
import { becomeSeller, type FormState } from "@/server/actions/auth";
import { Notice, buttonClass } from "@/components/ui";

export function BecomeSellerButton() {
  const [state, action, pending] = useActionState<FormState>(becomeSeller, {});
  return (
    <form action={action} className="space-y-3">
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <button className={buttonClass} disabled={pending}>
        {pending ? "Setting up your shop…" : "Start selling"}
      </button>
    </form>
  );
}
