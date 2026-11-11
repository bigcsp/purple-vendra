import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card, buttonClass } from "@/components/ui";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getMyVerification, verificationLabel } from "@/lib/verification";

export const metadata: Metadata = { title: "Seller hub · Purple Vendra" };

export default function SellPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your seller hub…</p>}>
        <SellerHub />
      </Suspense>
    </PageShell>
  );
}

async function SellerHub() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/sell");
  if (user.role === "buyer") redirect("/account");
  // The proxy already sends sellers without a 2FA-confirmed session away;
  // this is a second check in case the page is reached another way.
  if (!user.is2faConfirmed) redirect("/account/security?next=/sell");

  const verification = await getMyVerification(user.id);
  const label = verificationLabel[verification.status];

  return (
    <div className="space-y-6">
      <Card>
        <p className="text-sm font-medium uppercase tracking-widest text-accent">Seller hub</p>
        <h1 className="mt-2 text-2xl font-bold text-brand-strong">Welcome, {user.displayName}</h1>
        <p className="mt-2 text-sm text-green-700">✓ Signed in with two-factor authentication</p>
      </Card>
      <Card>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <h2 className="text-lg font-semibold text-brand-strong">ID verification</h2>
          <span className={`rounded-full px-3 py-1 text-xs font-medium ${label.tone}`}>{label.text}</span>
        </div>
        <p className="mt-1 text-sm text-muted">
          {verification.status === "approved"
            ? "You're verified. Buyers see the verified badge on your profile."
            : verification.status === "pending"
              ? "We're reviewing your ID."
              : "Verify your ID to get the verified badge, receive payouts and offer home services."}
        </p>
        {verification.status !== "approved" && (
          <Link href="/sell/verify" className={`${buttonClass} mt-4 sm:w-auto`}>
            {verification.status === "none" ? "Verify your ID" : "View or replace upload"}
          </Link>
        )}
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Your listings</h2>
        <p className="mt-1 text-sm text-muted">
          Creating listings, photos and your professional profile is coming next. You&apos;ll
          manage them all from here.
        </p>
      </Card>
    </div>
  );
}
