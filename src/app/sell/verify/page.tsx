import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card, Notice } from "@/components/ui";
import { getCurrentUser } from "@/lib/auth";
import { ID_TYPES } from "@/lib/id-types";
import { getMyVerification, verificationLabel } from "@/lib/verification";
import { VerifyIdForm } from "./verify-id-form";

export const metadata: Metadata = { title: "Verify your ID · Purple Vendra" };

export default function VerifyIdPage({ searchParams }: PageProps<"/sell/verify">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <Body searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

async function Body({ searchParams }: Pick<PageProps<"/sell/verify">, "searchParams">) {
  const [user, params] = await Promise.all([getCurrentUser(), searchParams]);
  if (!user) redirect("/login?next=/sell/verify");
  if (user.role === "buyer") redirect("/account");
  if (user.accountStatus !== "active") redirect("/account");
  if (!user.is2faConfirmed) redirect("/account/security?next=/sell/verify");

  const v = await getMyVerification(user.id);
  const label = verificationLabel[v.status];

  return (
    <div className="space-y-6">
      <Link href="/sell" className="text-sm font-medium text-brand">
        ← Seller hub
      </Link>

      <Card>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-brand-strong">Verify your ID</h1>
            <p className="mt-1 max-w-lg text-sm text-muted">
              Buyers trust verified sellers more. You need an approved ID to receive payouts and to
              offer home services.
            </p>
          </div>
          <span className={`rounded-full px-3 py-1 text-xs font-medium ${label.tone}`}>{label.text}</span>
        </div>
      </Card>

      {params.submitted === "1" && v.status === "pending" && (
        <Notice tone="success">Thanks! Your ID was submitted. We&apos;ll review it and update you here.</Notice>
      )}

      {v.status === "approved" ? (
        <Card>
          <p className="text-green-700">
            ✓ Your {v.idType ? ID_TYPES[v.idType] : "ID"} is verified. The verified badge now shows on
            your profile.
          </p>
        </Card>
      ) : (
        <Card>
          {v.status === "pending" && (
            <p className="mb-5 text-sm text-muted">
              Your {v.idType ? ID_TYPES[v.idType] : "ID"} is being reviewed. Uploaded the wrong file? You
              can replace it below.
            </p>
          )}
          {v.status === "rejected" && (
            <div className="mb-5">
              <Notice tone="error">
                We couldn&apos;t verify your last upload
                {v.rejectionReason ? `: ${v.rejectionReason}` : "."} Please upload a new one.
              </Notice>
            </div>
          )}
          <VerifyIdForm userId={user.id} currentType={v.idType} />
        </Card>
      )}
    </div>
  );
}
