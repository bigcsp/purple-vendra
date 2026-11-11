import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { signOut } from "@/app/actions/auth";
import { PageShell } from "@/components/page-shell";
import { Card, buttonClass } from "@/components/ui";
import { getCurrentUser, type CurrentUser } from "@/lib/auth";
import { BecomeSellerButton } from "./become-seller";

export const metadata: Metadata = { title: "Your account · Purple Vendra" };

const roleLabel = { buyer: "Buyer", seller: "Seller", admin: "Admin" } as const;

export default function AccountPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your account…</p>}>
        <Account />
      </Suspense>
    </PageShell>
  );
}

async function Account() {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/account");

  return (
    <div className="space-y-6">
      {user.accountStatus !== "active" && <AccountBlocked user={user} />}
      <Card>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-brand-strong">{user.displayName}</h1>
            <p className="text-sm text-muted">
              @{user.username} · {user.email}
            </p>
          </div>
          <span className="rounded-full bg-brand-soft px-3 py-1 text-xs font-medium text-brand">
            {roleLabel[user.role]}
          </span>
        </div>
      </Card>

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Two-factor authentication</h2>
        {user.has2fa ? (
          <p className="mt-1 text-sm text-green-700">On. Your account asks for a code from your phone.</p>
        ) : (
          <>
            <p className="mt-1 text-sm text-muted">
              Off. Turn it on to protect your account. Every seller needs it.
            </p>
            <Link href="/account/security" className={`${buttonClass} mt-4 sm:w-auto`}>
              Turn on 2FA
            </Link>
          </>
        )}
      </Card>

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Selling on Purple Vendra</h2>
        {user.role === "buyer" ? (
          user.has2fa ? (
            <>
              <p className="mt-1 mb-4 text-sm text-muted">
                You&apos;re ready. Open your shop to start listing products, services or talent.
              </p>
              <BecomeSellerButton />
            </>
          ) : (
            <>
              <p className="mt-1 text-sm text-muted">
                Step 1: turn on two-factor authentication. Step 2: open your shop.
              </p>
              <Link
                href="/account/security?next=/account"
                className={`${buttonClass} mt-4 sm:w-auto`}
              >
                Turn on 2FA to start selling
              </Link>
            </>
          )
        ) : (
          <>
            <p className="mt-1 text-sm text-muted">Your shop is open.</p>
            <Link href="/sell" className={`${buttonClass} mt-4 sm:w-auto`}>
              Go to seller hub
            </Link>
          </>
        )}
      </Card>

      <form action={signOut}>
        <button className="text-sm font-medium text-muted hover:text-brand">Sign out</button>
      </form>
    </div>
  );
}

function AccountBlocked({ user }: { user: CurrentUser }) {
  const until = user.suspendedUntil
    ? new Date(user.suspendedUntil).toLocaleDateString("en-NG", { day: "numeric", month: "long", year: "numeric" })
    : null;
  return (
    <div className="rounded-3xl border border-red-200 bg-red-50 p-6 text-red-800">
      <h2 className="text-lg font-semibold">
        {user.accountStatus === "banned" ? "Your account has been closed" : "Your account is suspended"}
      </h2>
      {user.statusReason && <p className="mt-1 text-sm">Reason: {user.statusReason}</p>}
      <p className="mt-1 text-sm">
        {user.accountStatus === "suspended" && until
          ? `You can sell and buy again from ${until}. `
          : ""}
        Until then you can&apos;t post, edit listings or place orders. If you think this is a
        mistake, contact Purple Vendra support.
      </p>
    </div>
  );
}
