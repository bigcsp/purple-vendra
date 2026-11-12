import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { ReportButton } from "@/components/report-button";
import { OfferForm } from "@/components/requests/offer-form";
import { OfferList } from "@/components/requests/offer-list";
import { RequestForm } from "@/components/requests/request-form";
import { Card, Notice } from "@/components/ui";
import { getCurrentUser } from "@/lib/auth";
import { getCategories } from "@/lib/catalog";
import { formatNaira } from "@/lib/money";
import { getOffers, getRequest, postedAgo, timeLeft } from "@/lib/requests";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Request · Purple Shop" };

export default function RequestPage({ params, searchParams }: PageProps<"/requests/[id]">) {
  return (
    <PageShell>
      <Link href="/requests" className="text-sm text-muted hover:text-brand">← Purple Requests</Link>
      <Suspense fallback={<p className="mt-6 text-sm text-muted">Loading request…</p>}>
        <Detail params={params} searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

async function Detail({
  params,
  searchParams,
}: {
  params: PageProps<"/requests/[id]">["params"];
  searchParams: PageProps<"/requests/[id]">["searchParams"];
}) {
  const [{ id }, sp] = await Promise.all([params, searchParams]);
  const r = await getRequest(id);
  if (!r) notFound();
  const [user, categories] = await Promise.all([getCurrentUser(), getCategories()]);
  const category = categories.find((c) => c.id === r.category_id);
  const open = r.status === "open";
  const where = r.city ? `${r.city}, ${r.state}` : r.state;
  const isSeller = !!user && user.role !== "buyer";

  return (
    <div className="mt-4 space-y-6">
      {sp.posted === "1" && r.is_owner && (
        <Notice tone="success">Your request is live. Sellers can now send you offers, and you&apos;ll see them below.</Notice>
      )}

      <Card>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-xs text-muted">
              {category?.name} · {r.is_owner ? "Your request" : r.buyer_username ? `@${r.buyer_username}` : `A buyer in ${where}`}
            </p>
            <h1 className="mt-1 text-2xl font-bold text-brand-strong">{r.title}</h1>
          </div>
          <span className={`rounded-full px-3 py-1 text-sm font-medium ${open ? "bg-green-50 text-green-800" : "bg-brand-soft text-muted"}`}>
            {open ? (r.is_full ? "Full" : "Open") : r.status === "expired" ? "Expired" : "Closed"}
          </span>
        </div>
        <dl className="mt-4 grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
          <div><dt className="text-muted">Budget</dt><dd className="font-semibold">{r.budget_kobo ? formatNaira(r.budget_kobo) : "Open to offers"}</dd></div>
          <div><dt className="text-muted">Location</dt><dd className="font-semibold">{where}</dd></div>
          <div>
            <dt className="text-muted">Needed by</dt>
            <dd className="font-semibold">
              {r.deadline ? new Date(r.deadline).toLocaleDateString("en-NG", { day: "numeric", month: "short", year: "numeric", timeZone: "Africa/Lagos" }) : "Flexible"}
            </dd>
          </div>
          <div><dt className="text-muted">Offers</dt><dd className="font-semibold">{r.offer_count} of 10</dd></div>
        </dl>
        <p className="mt-5 whitespace-pre-line">{r.description}</p>
        <p className="mt-4 text-xs text-muted">
          Posted {postedAgo(r.created_at)}{open && <> · {timeLeft(r.expires_at)}</>}
        </p>
      </Card>

      {r.is_owner ? (
        <OwnerView id={r.id} open={open} canEdit={open && r.offer_count === 0} categories={categories}
          initial={{ title: r.title, description: r.description, categoryId: r.category_id, budget: r.budget_kobo ? String(r.budget_kobo / 100) : "", state: r.state, city: r.city ?? "", deadline: r.deadline ?? "" }} />
      ) : (
        <Card>
          <h2 className="text-lg font-semibold text-brand-strong">
            {r.my_offer_status === "accepted" ? "Your offer was accepted 🎉" : r.my_offer_id ? "Your offer" : "Send an offer"}
          </h2>
          <div className="mt-4">
            {r.my_offer_status === "accepted" ? (
              <div className="space-y-3 text-sm">
                <p>The buyer accepted your offer of {formatNaira(r.my_offer_price_kobo)}. Agree the details in the chat; payment goes through Purple Shop escrow.</p>
                {r.chat_id && <Link href={`/messages/${r.chat_id}`} className="inline-block rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-deep">Open chat</Link>}
              </div>
            ) : r.my_offer_status === "declined" ? (
              <p className="text-sm text-muted">The buyer went with another offer this time. Keep an eye on the board for new requests.</p>
            ) : !open ? (
              <p className="text-sm text-muted">This request isn&apos;t taking offers any more.</p>
            ) : !user ? (
              <div className="text-sm">
                <p className="text-muted">Sellers can send an offer with their price and how long it will take.</p>
                <div className="mt-3 flex flex-wrap gap-2">
                  <Link href={`/signup?reason=offer&next=/requests/${r.id}`} className="rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-deep">Join to send an offer</Link>
                  <Link href={`/login?next=/requests/${r.id}`} className="rounded-full border border-border px-4 py-2 font-medium text-brand hover:bg-brand-soft">Sign in</Link>
                </div>
              </div>
            ) : !isSeller ? (
              <div className="text-sm">
                <p className="text-muted">Only sellers can send offers. Do you make or offer this? Open your free shop first.</p>
                <Link href="/welcome" className="mt-3 inline-block rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-deep">Start selling</Link>
              </div>
            ) : r.is_full && !r.my_offer_id ? (
              <p className="text-sm text-muted">This request already has 10 offers.</p>
            ) : (
              <SellerOffer requestId={r.id} userId={user.id}
                existing={r.my_offer_id ? { id: r.my_offer_id, status: r.my_offer_status!, priceKobo: r.my_offer_price_kobo!, days: r.my_offer_days, message: r.my_offer_message ?? "", listingId: r.my_offer_listing } : null} />
            )}
          </div>
        </Card>
      )}

      {!r.is_owner && open && (
        <div className="space-y-3">
          <p className="rounded-2xl bg-brand-soft/60 px-4 py-3 text-xs text-brand-strong">
            🔒 Offers and chats stay on Purple Shop. Contact details are blocked and the buyer pays through escrow, so
            you&apos;re paid once the job is confirmed.
          </p>
          {user && <ReportButton requestId={r.id} />}
        </div>
      )}
    </div>
  );
}

async function SellerOffer({
  requestId,
  userId,
  existing,
}: {
  requestId: string;
  userId: string;
  existing: { id: string; status: string; priceKobo: number; days: number | null; message: string; listingId: string | null } | null;
}) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("listings")
    .select("id, title")
    .eq("seller_id", userId)
    .eq("status", "approved")
    .order("created_at", { ascending: false })
    .limit(50);
  return <OfferForm requestId={requestId} listings={(data ?? []) as { id: string; title: string }[]} existing={existing} />;
}

async function OwnerView({
  id,
  open,
  canEdit,
  categories,
  initial,
}: {
  id: string;
  open: boolean;
  canEdit: boolean;
  categories: { id: number; name: string; section: string }[];
  initial: Parameters<typeof RequestForm>[0]["initial"];
}) {
  const offers = await getOffers(id);
  return (
    <>
      <section>
        <h2 className="mb-3 text-lg font-semibold text-brand-strong">
          Offers {offers.length > 0 && <span className="text-muted">({offers.filter((o) => o.status !== "declined").length})</span>}
        </h2>
        <OfferList requestId={id} offers={offers} open={open} />
      </section>
      {canEdit && (
        <details className="rounded-3xl border border-border bg-card p-5">
          <summary className="cursor-pointer font-medium text-brand">Edit request</summary>
          <p className="mt-1 text-xs text-muted">You can edit until the first offer arrives.</p>
          <div className="mt-4">
            <RequestForm categories={categories} initial={initial} requestId={id} />
          </div>
        </details>
      )}
    </>
  );
}
