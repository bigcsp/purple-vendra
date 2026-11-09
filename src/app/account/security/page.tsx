import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card, Notice } from "@/components/ui";
import { getCurrentUser } from "@/lib/auth";
import { safeNext } from "@/lib/safe-next";
import { Setup2fa } from "./setup-2fa";

export const metadata: Metadata = { title: "Two-factor authentication · Purple Vendra" };

export default function SecurityPage({ searchParams }: PageProps<"/account/security">) {
  return (
    <PageShell narrow>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Two-factor authentication</h1>
        <p className="mt-1 mb-6 text-sm text-muted">
          2FA protects your shop and your earnings. Even if someone learns your password, they
          can&apos;t sign in without the code on your phone. Every seller needs it.
        </p>
        <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
          <Body searchParams={searchParams} />
        </Suspense>
      </Card>
    </PageShell>
  );
}

async function Body({ searchParams }: Pick<PageProps<"/account/security">, "searchParams">) {
  const [user, { next }] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user) redirect("/login?next=/account/security");

  if (user.has2fa) {
    return (
      <div className="space-y-4">
        <Notice tone="success">2FA is on. You&apos;ll be asked for a code each time you sign in.</Notice>
        <Link href={safeNext(next)} className="block text-center text-sm font-medium text-brand">
          Continue
        </Link>
      </div>
    );
  }

  return <Setup2fa next={safeNext(next)} />;
}
