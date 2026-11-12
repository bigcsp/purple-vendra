import type { Metadata } from "next";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { safeNext } from "@/lib/safe-next";
import { LoginForm } from "./login-form";

export const metadata: Metadata = { title: "Sign in · Purple Shop" };

export default function LoginPage({ searchParams }: PageProps<"/login">) {
  return (
    <PageShell narrow>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Welcome back</h1>
        <p className="mt-1 mb-6 text-sm text-muted">Sign in to your Purple Shop account.</p>
        <Suspense>
          <Form searchParams={searchParams} />
        </Suspense>
      </Card>
    </PageShell>
  );
}

async function Form({ searchParams }: Pick<PageProps<"/login">, "searchParams">) {
  const params = await searchParams;
  return <LoginForm next={safeNext(params.next)} linkError={params.error === "link"} />;
}
