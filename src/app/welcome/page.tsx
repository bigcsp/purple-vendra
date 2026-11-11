import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { BecomeSellerButton } from "@/app/account/become-seller";
import { AdireField } from "@/components/adire";
import { PageShell } from "@/components/page-shell";
import { Card, buttonClass } from "@/components/ui";
import { getCurrentUser, type CurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { getMyVerification } from "@/lib/verification";

export const metadata: Metadata = { title: "Welcome · Purple Vendra" };

export default function WelcomePage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <Welcome />
      </Suspense>
    </PageShell>
  );
}

async function Welcome() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/welcome");
  const wantsToSell = user.intent !== "shop" || user.role !== "buyer";
  const firstName = user.displayName.split(" ")[0];

  return (
    <div className="space-y-6">
      <div className="relative overflow-hidden rounded-3xl bg-panel px-6 py-8 text-white">
        <AdireField className="pointer-events-none absolute -right-10 top-0 h-full w-72 opacity-60" />
        <div className="relative">
        <p className="text-sm font-medium text-accent">Welcome</p>
        <h1 className="mt-1 text-2xl font-bold">You&apos;re in, {firstName}! 🎉</h1>
        <p className="mt-1 text-white/85">
          {wantsToSell
            ? "Let's open your shop. Follow the steps below. Each one takes a minute or two."
            : "Explore Nigerian makers, freelancers and pros. Your money is held safely until you receive what you paid for."}
        </p>
        </div>
      </div>

      {wantsToSell && <SellerChecklist user={user} />}

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">{wantsToSell ? "Look around while you set up" : "Start exploring"}</h2>
        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <Link href="/stories" className="rounded-2xl border border-border p-4 hover:border-brand">
            <span className="text-2xl">🎬</span>
            <span className="mt-1 block font-medium">Vendra Stories</span>
            <span className="block text-xs text-muted">Watch makers at work, shop what you see</span>
          </Link>
          <Link href="/search" className="rounded-2xl border border-border p-4 hover:border-brand">
            <span className="text-2xl">🔎</span>
            <span className="mt-1 block font-medium">Search</span>
            <span className="block text-xs text-muted">Adire, logo design, plumbers and more</span>
          </Link>
          <Link href="/" className="rounded-2xl border border-border p-4 hover:border-brand">
            <span className="text-2xl">🧭</span>
            <span className="mt-1 block font-medium">Browse categories</span>
            <span className="block text-xs text-muted">Creative, freelance and home services</span>
          </Link>
        </div>
        {!wantsToSell && (
          <p className="mt-4 text-sm text-muted">
            Have a skill or product to sell?{" "}
            <Link href="/account/security?next=/welcome" className="font-medium text-brand underline">Open a shop</Link>. It&apos;s free.
          </p>
        )}
      </Card>
    </div>
  );
}

async function SellerChecklist({ user }: { user: CurrentUser }) {
  const supabase = await createClient();
  const isSeller = user.role !== "buyer";
  const [{ data: profile }, { count: listings }, { count: stories }, verification] = await Promise.all([
    supabase.from("profiles").select("business_name, headline, avatar_url").eq("id", user.id).single(),
    isSeller ? supabase.from("listings").select("id", { count: "exact", head: true }).eq("seller_id", user.id) : Promise.resolve({ count: 0 }),
    isSeller ? supabase.from("story_videos").select("id", { count: "exact", head: true }).eq("seller_id", user.id) : Promise.resolve({ count: 0 }),
    isSeller ? getMyVerification(user.id) : Promise.resolve({ status: "none" as const }),
  ]);

  const profileDone = !!(profile?.business_name && profile?.headline);
  const steps: { done: boolean; title: string; text: string; action?: React.ReactNode; optional?: boolean }[] = [
    {
      done: user.has2fa,
      title: "Protect your shop with 2FA",
      text: "Scan a QR code with Google Authenticator (free). It keeps your earnings safe even if your password leaks.",
      action: <Link href="/account/security?next=/welcome" className={`${buttonClass} sm:w-auto`}>Turn on 2FA</Link>,
    },
    {
      done: isSeller,
      title: "Open your shop",
      text: "One tap. Your shop page goes live at /shop/" + user.username + ".",
      action: !user.has2fa ? undefined : !user.is2faConfirmed ? (
        <Link href="/login/verify?next=/welcome" className={`${buttonClass} sm:w-auto`}>Enter your 2FA code first</Link>
      ) : (
        <div className="sm:w-56"><BecomeSellerButton /></div>
      ),
    },
    {
      done: profileDone,
      title: "Add your shop details",
      text: "Logo, business name, headline, working hours and where you deliver. Buyers trust complete shops.",
      action: isSeller ? <Link href="/sell/profile" className={`${buttonClass} sm:w-auto`}>Edit shop profile</Link> : undefined,
    },
    {
      done: (listings ?? 0) > 0,
      title: "Add your first product or service",
      text: "Photos, price and description. Our team checks it quickly, then it's live.",
      action: isSeller ? <Link href="/sell/listings/new" className={`${buttonClass} sm:w-auto`}>Add a listing</Link> : undefined,
    },
    {
      done: (stories ?? 0) > 0,
      title: "Post a Vendra Story",
      text: "A short video of you at work. Tag your products so buyers can shop while they watch.",
      action: isSeller ? <Link href="/sell/stories/new" className={`${buttonClass} sm:w-auto`}>Post a story</Link> : undefined,
    },
    {
      done: verification.status === "approved" || verification.status === "pending",
      title: verification.status === "pending" ? "ID verification (under review)" : "Verify your ID",
      text: "Gets you the ✓ verified badge and lets you receive payouts. Needed for home services.",
      action: isSeller && verification.status !== "pending" ? <Link href="/sell/verify" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">Verify ID</Link> : undefined,
      optional: true,
    },
  ];
  const doneCount = steps.filter((s) => s.done).length;
  const nextIndex = steps.findIndex((s) => !s.done);

  return (
    <Card>
      <div className="flex flex-wrap items-end justify-between gap-2">
        <h2 className="text-lg font-semibold text-brand-strong">Open your shop</h2>
        <span className="text-sm text-muted">{doneCount} of {steps.length} done</span>
      </div>
      <div className="mt-2 h-2 overflow-hidden rounded-full bg-brand-soft">
        <div className="h-full bg-brand transition-all" style={{ width: `${(doneCount / steps.length) * 100}%` }} />
      </div>
      <ol className="mt-5 space-y-3">
        {steps.map((s, i) => (
          <li key={s.title}
            className={`rounded-2xl border p-4 ${i === nextIndex ? "border-brand bg-brand-soft/50" : "border-border"} ${s.done ? "opacity-70" : ""}`}>
            <div className="flex items-start gap-3">
              <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-sm font-bold ${s.done ? "bg-green-600 text-white" : "bg-card text-brand ring-1 ring-border"}`}>
                {s.done ? "✓" : i + 1}
              </span>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-brand-strong">
                  {s.title} {s.optional && <span className="text-xs font-normal text-muted">(optional for now)</span>}
                </p>
                <p className="text-sm text-muted">{s.text}</p>
                {!s.done && i === nextIndex && s.action && <div className="mt-3">{s.action}</div>}
              </div>
            </div>
          </li>
        ))}
      </ol>
      {doneCount === steps.length && (
        <p className="mt-4 text-sm font-medium text-green-700">
          Your shop is fully set up. <Link href={`/shop/${user.username}`} className="underline">See it live →</Link>
        </p>
      )}
    </Card>
  );
}
