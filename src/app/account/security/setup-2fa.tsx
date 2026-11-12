"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Field, Notice, buttonClass } from "@/components/ui";

type Enrollment = { factorId: string; qrCode: string; secret: string };

/** Turns on 2FA: scan a QR code with an authenticator app, then confirm a code. */
export function Setup2fa({ next }: { next: string }) {
  const router = useRouter();
  const [enrollment, setEnrollment] = useState<Enrollment>();
  const [error, setError] = useState<string>();
  const [pending, setPending] = useState(false);

  async function start() {
    setPending(true);
    setError(undefined);
    const supabase = createClient();

    // Clear any half-finished setup from an earlier attempt.
    const { data: factors } = await supabase.auth.mfa.listFactors();
    for (const f of factors?.all ?? []) {
      if (f.status === "unverified") await supabase.auth.mfa.unenroll({ factorId: f.id });
    }

    const { data, error } = await supabase.auth.mfa.enroll({
      factorType: "totp",
      friendlyName: "Authenticator app",
      issuer: "Purple Shop",
    });
    setPending(false);
    if (error || !data) {
      setError(error?.message ?? "Couldn't start setup. Please try again.");
      return;
    }
    setEnrollment({ factorId: data.id, qrCode: data.totp.qr_code, secret: data.totp.secret });
  }

  async function confirm(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!enrollment) return;
    setPending(true);
    setError(undefined);

    const code = String(new FormData(e.currentTarget).get("code") ?? "").replace(/\s/g, "");
    const { error } = await createClient().auth.mfa.challengeAndVerify({
      factorId: enrollment.factorId,
      code,
    });
    if (error) {
      setPending(false);
      setError("That code didn't work. Wait for a new code in the app and try again.");
      return;
    }
    router.replace(next);
    router.refresh();
  }

  if (!enrollment) {
    return (
      <div className="space-y-4">
        <ol className="list-decimal space-y-1 pl-5 text-sm text-muted">
          <li>Install an authenticator app on your phone (Google Authenticator, Microsoft Authenticator or Authy).</li>
          <li>Tap the button below and scan the QR code with the app.</li>
          <li>Type the 6-digit code the app shows you.</li>
        </ol>
        {error && <Notice tone="error">{error}</Notice>}
        <button className={buttonClass} onClick={start} disabled={pending}>
          {pending ? "Preparing…" : "Set up authenticator app"}
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={confirm} className="space-y-4">
      <div className="flex justify-center rounded-2xl border border-border bg-card p-4">
        {/* Supabase returns the QR code as an SVG data URL */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={enrollment.qrCode} alt="QR code for your authenticator app" className="h-48 w-48" />
      </div>
      <p className="text-xs text-muted">
        Can&apos;t scan? Enter this key in the app instead:{" "}
        <code className="break-all rounded bg-brand-soft px-1.5 py-0.5 text-brand-strong">{enrollment.secret}</code>
      </p>
      <Field
        label="6-digit code from the app"
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
        {pending ? "Checking…" : "Turn on 2FA"}
      </button>
    </form>
  );
}
