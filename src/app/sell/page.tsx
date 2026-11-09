import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCurrentUser } from "@/lib/auth";

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

  return (
    <div className="space-y-6">
      <Card>
        <p className="text-sm font-medium uppercase tracking-widest text-accent">Seller hub</p>
        <h1 className="mt-2 text-2xl font-bold text-brand-strong">Welcome, {user.displayName}</h1>
        <p className="mt-2 text-sm text-green-700">✓ Signed in with two-factor authentication</p>
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
