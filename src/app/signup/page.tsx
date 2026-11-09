import type { Metadata } from "next";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { SignupForm } from "./signup-form";

export const metadata: Metadata = { title: "Join Purple Vendra" };

export default function SignupPage() {
  return (
    <PageShell narrow>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Join Purple Vendra</h1>
        <p className="mt-1 mb-6 text-sm text-muted">
          Shop, hire and book with one account. You can start selling any time.
        </p>
        <SignupForm />
      </Card>
    </PageShell>
  );
}
