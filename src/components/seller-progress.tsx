import Link from "next/link";
import type { Milestone, SellerProgress } from "@/server/queries/seller-progress";

const STEPS: Record<Milestone, { label: string; next?: { text: string; href: string } }> = {
  signed_up: { label: "Joined Purple Shop" },
  two_factor_on: { label: "Turned on two-factor sign-in" },
  shop_opened: { label: "Opened your shop" },
  profile_completed: {
    label: "Completed your shop profile",
    next: { text: "Add your shop name, headline, about and location", href: "/sell/profile" },
  },
  first_listing_approved: {
    label: "First listing approved",
    next: { text: "Add your first product or service", href: "/sell/listings/new" },
  },
  id_verified: { label: "ID verified", next: { text: "Verify your ID to get the ✓ badge", href: "/sell/verify" } },
  bank_verified: { label: "Bank account verified", next: { text: "Add your bank account for payouts", href: "/sell/verify" } },
  first_sale: { label: "First sale", next: { text: "Share your shop or answer buyer requests", href: "/requests?view=matches" } },
  first_payout: { label: "First payout received" },
};

const fmt = (iso: string) =>
  new Date(iso).toLocaleDateString("en-NG", { day: "numeric", month: "short", year: "numeric", timeZone: "Africa/Lagos" });

/** The seller's onboarding timeline, from their permanent record. */
export function SellerProgressCard({ progress }: { progress: SellerProgress }) {
  const done = progress.steps.filter((s) => s.reachedAt).length;
  const nextStep = progress.steps.find((s) => !s.reachedAt && STEPS[s.milestone].next);

  return (
    <section className="rounded-3xl border border-border bg-card p-6">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-lg font-semibold text-brand-strong">Your progress</h2>
        <p className="text-xs text-muted">
          Seller {progress.sellerNumber} · since {fmt(progress.joinedAt)}
        </p>
      </div>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-brand-soft" role="progressbar" aria-valuemin={0} aria-valuemax={progress.steps.length} aria-valuenow={done} aria-label="Steps completed">
        <div className="h-full rounded-full bg-brand" style={{ width: `${(done / progress.steps.length) * 100}%` }} />
      </div>
      <p className="mt-2 text-sm text-muted">
        {done} of {progress.steps.length} steps done
      </p>

      {nextStep && STEPS[nextStep.milestone].next && (
        <Link href={STEPS[nextStep.milestone].next!.href} className="mt-4 flex items-center justify-between gap-3 rounded-2xl bg-brand-soft/60 px-4 py-3 text-sm hover:bg-brand-soft">
          <span>
            <span className="block text-xs text-muted">Next step</span>
            <span className="font-medium text-brand-strong">{STEPS[nextStep.milestone].next!.text}</span>
          </span>
          <span aria-hidden className="text-brand">→</span>
        </Link>
      )}

      <ol className="mt-4 space-y-2">
        {progress.steps.map((s) => (
          <li key={s.milestone} className="flex items-center gap-3 text-sm">
            <span
              className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold ${
                s.reachedAt ? "bg-brand text-white" : "border border-border text-muted"
              }`}
              aria-hidden
            >
              {s.reachedAt ? "✓" : ""}
            </span>
            <span className={`flex-1 ${s.reachedAt ? "" : "text-muted"}`}>
              {STEPS[s.milestone].label}
              <span className="sr-only">{s.reachedAt ? " (done)" : " (not yet)"}</span>
            </span>
            {s.reachedAt && <span className="text-xs text-muted">{fmt(s.reachedAt)}</span>}
          </li>
        ))}
      </ol>
    </section>
  );
}
