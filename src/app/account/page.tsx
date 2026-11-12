import { ClipboardList, Heart, MessageCircle, ShoppingBag } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { InstallAppCard } from "@/components/install-app";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { signOut } from "@/server/actions/auth";
import { PageShell } from "@/components/page-shell";
import { Card, buttonClass } from "@/components/ui";
import { getCurrentUser, type CurrentUser } from "@/server/auth/session";
import { BecomeSellerButton } from "./become-seller";

export const metadata: Metadata = { title: "Your account · Purple Shop" };

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
      {user.deletionRequestedAt && (
        <div className="rounded-3xl border border-amber-200 bg-amber-50 p-5 text-amber-900">
          <p className="font-semibold">Your account is set to be deleted</p>
          <p className="mt-1 text-sm">
            It will be deleted on{" "}
            {new Date(new Date(user.deletionRequestedAt).getTime() + 30 * 86400000).toLocaleDateString("en-NG", {
              day: "numeric",
              month: "long",
              year: "numeric",
            })}
            . Changed your mind?{" "}
            <Link href="/account/privacy" className="font-medium underline">Cancel the deletion</Link>.
          </p>
        </div>
      )}
      {user.role === "buyer" && user.intent !== "shop" && (
        <Link href="/welcome" className="block rounded-3xl border-2 border-brand bg-brand-soft p-5 hover:bg-brand-soft/70">
          <p className="font-semibold text-brand-strong">Finish opening your shop →</p>
          <p className="mt-1 text-sm text-muted">A few quick steps: turn on 2FA, open your shop, add your first product.</p>
        </Link>
      )}
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

      <InstallAppCard />

      <nav aria-label="Your things" className="grid grid-cols-2 gap-3 text-center text-sm sm:grid-cols-4">
        {[
          { href: "/requests/mine", icon: ClipboardList, label: "Requests" },
          { href: "/saved", icon: Heart, label: "Saved" },
          { href: "/messages", icon: MessageCircle, label: "Messages" },
          { href: "/cart", icon: ShoppingBag, label: "Cart" },
        ].map((x) => (
          <Link key={x.href} href={x.href} className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-card p-4 font-medium text-foreground transition-colors hover:border-brand hover:text-brand">
            <x.icon className="h-6 w-6 text-brand" strokeWidth={1.75} aria-hidden />
            {x.label}
          </Link>
        ))}
      </nav>

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
        <h2 className="text-lg font-semibold text-brand-strong">Selling on Purple Shop</h2>
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

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Your data & privacy</h2>
        <p className="mt-1 text-sm text-muted">Download everything we hold about you, or delete your account.</p>
        <Link href="/account/privacy" className="mt-3 inline-block text-sm font-medium text-brand hover:underline">
          Privacy settings →
        </Link>
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
        mistake, contact Purple Shop support.
      </p>
    </div>
  );
}
