import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card, buttonClass } from "@/components/ui";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getMyVerification, verificationLabel } from "@/lib/verification";

export const metadata: Metadata = { title: "Seller hub · Purple Shop" };

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
  if (user.accountStatus !== "active") redirect("/account");
  // The proxy already sends sellers without a 2FA-confirmed session away;
  // this is a second check in case the page is reached another way.
  if (!user.is2faConfirmed) redirect("/account/security?next=/sell");

  const verification = await getMyVerification(user.id);
  const label = verificationLabel[verification.status];

  return (
    <div className="space-y-6">
      <Card>
        <p className="text-sm font-medium text-accent">Seller hub</p>
        <h1 className="mt-2 text-2xl font-bold text-brand-strong">Welcome, {user.displayName}</h1>
        <p className="mt-2 text-sm text-green-700">✓ Signed in with two-factor authentication</p>
      </Card>
      <Card>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <h2 className="text-lg font-semibold text-brand-strong">ID verification</h2>
          <span className={`rounded-full px-3 py-1 text-xs font-medium ${label.tone}`}>{label.text}</span>
        </div>
        <p className="mt-1 text-sm text-muted">
          {verification.status === "approved"
            ? "You're verified. Buyers see the verified badge on your profile."
            : verification.status === "pending"
              ? "We're reviewing your ID."
              : "Verify your ID to get the verified badge, receive payouts and offer home services."}
        </p>
        {verification.status !== "approved" && (
          <Link href="/sell/verify" className={`${buttonClass} mt-4 sm:w-auto`}>
            {verification.status === "none" ? "Verify your ID" : "View or replace upload"}
          </Link>
        )}
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Your shop profile</h2>
        <p className="mt-1 text-sm text-muted">
          Logo, business name, headline, working hours and the areas you serve. A complete profile helps buyers trust you
          and find you in search.
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Link href="/sell/profile" className={`${buttonClass} sm:w-auto`}>Edit shop profile</Link>
          <Link href={`/shop/${user.username}`} className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            View my shop
          </Link>
        </div>
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Your listings</h2>
        <p className="mt-1 text-sm text-muted">
          Products, services and talent you sell. New listings are reviewed before they go live.
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Link href="/sell/listings" className={`${buttonClass} sm:w-auto`}>Manage listings</Link>
          <Link href="/sell/listings/new" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            + New listing
          </Link>
        </div>
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Orders</h2>
        <p className="mt-1 text-sm text-muted">See what buyers have paid for, and what to ship next.</p>
        <Link href="/sell/orders" className={`${buttonClass} mt-4 sm:w-auto`}>View orders</Link>
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Buyer requests</h2>
        <p className="mt-1 text-sm text-muted">
          Buyers post what they need with a budget. Send an offer with your price and timing; if they accept, a chat
          opens and they pay through escrow.
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Link href="/requests?view=matches" className={`${buttonClass} sm:w-auto`}>See matching requests</Link>
          <Link href="/requests/mine" className="inline-flex items-center rounded-xl border border-border px-4 py-2.5 font-medium text-brand hover:bg-brand-soft">My offers</Link>
        </div>
      </Card>
      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Messages</h2>
        <p className="mt-1 text-sm text-muted">
          Answer buyers&apos; questions here. Keep every deal on Purple Shop: phone numbers, social handles and bank
          details are blocked, and buyers pay only through escrow, which is what protects you from fake payment alerts.
        </p>
        <Link href="/messages" className={`${buttonClass} mt-4 sm:w-auto`}>Open messages</Link>
      </Card>
      <Card>
        <p className="text-xs font-semibold text-accent">New</p>
        <h2 className="text-lg font-semibold text-brand-strong">Purple Stories</h2>
        <p className="mt-1 text-sm text-muted">
          Post short videos to your shop page, tag your products so buyers can shop while they watch, promote your best
          videos and track views, engagement and sales.
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Link href="/sell/stories/new" className={`${buttonClass} sm:w-auto`}>Post a story</Link>
          <Link href="/sell/stories" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">My stories</Link>
          <Link href="/sell/stories/analytics" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">Analytics</Link>
          <Link href="/sell/stories/promote" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">Promote</Link>
          <Link href={`/shop/${user.username}`} className="px-2 py-2.5 text-sm text-muted hover:text-brand">View my shop →</Link>
        </div>
      </Card>
    </div>
  );
}
