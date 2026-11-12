import type { Metadata } from "next";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { safeNext } from "@/lib/safe-next";
import { SignupForm } from "./signup-form";

export const metadata: Metadata = { title: "Join Purple Shop" };

/** Why a visitor was sent here (shown as a friendly line at the top). */
const REASONS: Record<string, string> = {
  cart: "Create a free account to add this to your cart. You'll come straight back.",
  like: "Create a free account to like stories and keep track of what you love.",
  follow: "Create a free account to follow this shop and see their new work.",
  comment: "Create a free account to join the conversation.",
  report: "Create a free account to report this. It keeps reports honest.",
  request: "Create a free account to post your request. Your name stays hidden from sellers.",
  offer: "Create a seller account to send offers on buyer requests.",
  save: "Create a free account to save this and find it again on any device.",
  message: "Create a free account to message this seller. Your email and phone number stay private.",
};

export default function SignupPage({ searchParams }: PageProps<"/signup">) {
  return (
    <PageShell narrow>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">Join Purple Shop</h1>
        <Suspense fallback={<p className="mt-4 text-sm text-muted">Loading…</p>}>
          <Body searchParams={searchParams} />
        </Suspense>
      </Card>
    </PageShell>
  );
}

async function Body({ searchParams }: Pick<PageProps<"/signup">, "searchParams">) {
  const params = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";
  const intent = one(params.intent);
  const reason = REASONS[one(params.reason)];
  return (
    <>
      <p className="mt-1 mb-6 text-sm text-muted">
        {reason ?? "Free to join. Shop from Nigerian makers, hire freelancers, or open your own shop."}
      </p>
      <SignupForm
        next={safeNext(params.next, "")}
        initialIntent={intent === "sell" || intent === "both" ? intent : "shop"}
      />
    </>
  );
}
