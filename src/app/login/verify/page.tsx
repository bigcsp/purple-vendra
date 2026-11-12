import type { Metadata } from "next";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { safeNext } from "@/lib/safe-next";
import { VerifyForm } from "./verify-form";

export const metadata: Metadata = { title: "Enter your code · Purple Shop" };

export default function VerifyPage({ searchParams }: PageProps<"/login/verify">) {
  return (
    <PageShell narrow>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Enter your code</h1>
        <p className="mt-1 mb-6 text-sm text-muted">
          Open your authenticator app (Google Authenticator, Microsoft Authenticator, Authy…) and
          type the 6-digit code for Purple Shop.
        </p>
        <Suspense>
          <Form searchParams={searchParams} />
        </Suspense>
      </Card>
    </PageShell>
  );
}

async function Form({ searchParams }: Pick<PageProps<"/login/verify">, "searchParams">) {
  const { next } = await searchParams;
  return <VerifyForm next={safeNext(next)} />;
}
