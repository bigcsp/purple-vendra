import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { RequestForm } from "@/components/requests/request-form";
import { Card } from "@/components/ui";
import { getCurrentUser } from "@/server/auth/session";
import { getCategories } from "@/server/queries/catalog";

export const metadata: Metadata = { title: "Post a request · Purple Shop" };

export default function NewRequestPage({ searchParams }: PageProps<"/requests/new">) {
  return (
    <PageShell>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Post a request</h1>
        <p className="mt-1 text-sm text-muted">Tell sellers what you need. You&apos;ll get up to 10 offers to compare.</p>
        <div className="mt-6">
          <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
            <Form searchParams={searchParams} />
          </Suspense>
        </div>
      </Card>
    </PageShell>
  );
}

async function Form({ searchParams }: { searchParams: PageProps<"/requests/new">["searchParams"] }) {
  const user = await getCurrentUser();
  if (!user) redirect("/signup?reason=request&next=/requests/new");
  const [{ title, category }, categories] = await Promise.all([searchParams, getCategories()]);
  const preset = categories.find((c) => c.slug === category);
  return (
    <RequestForm
      categories={categories}
      initial={{
        title: typeof title === "string" ? title.slice(0, 120) : "",
        description: "",
        categoryId: preset?.id ?? categories[0]?.id ?? 0,
        budget: "",
        state: "",
        city: "",
        deadline: "",
      }}
    />
  );
}
