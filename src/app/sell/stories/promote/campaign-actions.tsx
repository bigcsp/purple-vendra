"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { setCampaignStatus } from "@/server/actions/campaigns";

export function CampaignActions({ id, status }: { id: string; status: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  const run = (next: "cancelled" | "paused" | "active", confirmText?: string) => {
    if (confirmText && !confirm(confirmText)) return;
    start(async () => {
      const r = await setCampaignStatus(id, next);
      if (r.error) setError(r.error);
      else router.refresh();
    });
  };
  return (
    <span className="flex flex-wrap gap-3 text-xs font-medium">
      {status === "awaiting_payment" && (
        <button disabled={pending} onClick={() => run("cancelled", "Cancel this campaign?")} className="text-red-600 hover:underline">Cancel</button>
      )}
      {status === "active" && <button disabled={pending} onClick={() => run("paused")} className="text-brand hover:underline">Pause</button>}
      {status === "paused" && <button disabled={pending} onClick={() => run("active")} className="text-brand hover:underline">Resume</button>}
      {error && <span className="text-red-700">{error}</span>}
    </span>
  );
}
