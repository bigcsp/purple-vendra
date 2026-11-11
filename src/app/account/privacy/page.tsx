import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCurrentUser } from "@/lib/auth";
import { DeleteAccount } from "./delete-account";

export const metadata: Metadata = { title: "Privacy settings · Purple Vendra" };

export default function PrivacySettingsPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <PrivacySettings />
      </Suspense>
    </PageShell>
  );
}

async function PrivacySettings() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/account/privacy");

  return (
    <div className="space-y-6">
      <div>
        <Link href="/account" className="text-sm text-muted hover:text-brand">← Your account</Link>
        <h1 className="text-2xl font-bold text-brand-strong">Your data & privacy</h1>
        <p className="text-sm text-muted">
          Your rights under Nigeria&apos;s Data Protection Act. Read our <Link href="/privacy" className="text-brand underline">privacy policy</Link>.
        </p>
      </div>

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Download your data</h2>
        <p className="mt-1 text-sm text-muted">
          A file with everything we hold about you: your profile, listings, stories, orders, messages, reviews and more.
          You can download it up to 5 times a day.
        </p>
        <a href="/account/privacy/export" download className="mt-4 inline-flex rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
          Download my data (JSON)
        </a>
      </Card>

      <Card>
        <h2 className="text-lg font-semibold text-red-700">Delete your account</h2>
        <DeleteAccount username={user.username} requestedAt={user.deletionRequestedAt} has2fa={user.has2fa} confirmed2fa={user.is2faConfirmed} />
      </Card>
    </div>
  );
}
