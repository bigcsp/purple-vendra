import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { formatNaira } from "@/lib/money";
import { requireSeller } from "@/lib/seller";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Orders · Seller hub" };

const STATUS: Record<string, { text: string; tone: string; hint: string }> = {
  paid: { text: "New · paid", tone: "bg-amber-100 text-amber-800", hint: "Payment is held safely. Prepare and ship." },
  shipped: { text: "Shipped", tone: "bg-blue-100 text-blue-800", hint: "Waiting for the buyer to receive it." },
  delivered: { text: "Delivered", tone: "bg-brand-soft text-brand", hint: "Waiting for the buyer to confirm." },
  completed: { text: "Completed", tone: "bg-green-100 text-green-800", hint: "Payment released to you." },
  disputed: { text: "Disputed", tone: "bg-red-100 text-red-700", hint: "Funds frozen while we review." },
  refunded: { text: "Refunded", tone: "bg-gray-100 text-gray-600", hint: "" },
  cancelled: { text: "Cancelled", tone: "bg-gray-100 text-gray-600", hint: "" },
};

type Order = {
  id: string;
  status: string;
  subtotal_kobo: number;
  delivery_fee_kobo: number;
  seller_payout_kobo: number;
  created_at: string;
  order_items: { title_snapshot: string; quantity: number; unit_price_kobo: number }[];
};

export default function SellerOrdersPage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your orders…</p>}>
        <Orders />
      </Suspense>
    </PageShell>
  );
}

async function Orders() {
  const user = await requireSeller("/sell/orders");
  const supabase = await createClient();
  const { data } = await supabase
    .from("orders")
    .select("id, status, subtotal_kobo, delivery_fee_kobo, seller_payout_kobo, created_at, order_items(title_snapshot, quantity, unit_price_kobo)")
    .eq("seller_id", user.id)
    .order("created_at", { ascending: false })
    .limit(100);
  const orders = (data ?? []) as Order[];
  const open = orders.filter((o) => ["paid", "shipped", "delivered", "disputed"].includes(o.status));

  return (
    <div className="space-y-6">
      <div>
        <Link href="/sell" className="text-sm text-muted hover:text-brand">← Seller hub</Link>
        <h1 className="text-2xl font-bold text-brand-strong">Orders</h1>
        {orders.length > 0 && (
          <p className="text-sm text-muted">{open.length} open · {orders.length} total</p>
        )}
      </div>

      {orders.length === 0 ? (
        <Card>
          <h2 className="font-semibold text-brand-strong">No orders yet</h2>
          <p className="mt-1 text-sm text-muted">
            When a buyer pays for one of your listings, the order appears here. Purple Vendra holds the payment safely
            until the buyer confirms delivery, then releases it to you. Online checkout is being switched on next. Until
            then, buyers can add your products to their cart.
          </p>
          <div className="mt-4 flex flex-wrap gap-2 text-sm">
            <Link href="/sell/listings/new" className="rounded-xl border border-border px-4 py-2 font-medium text-brand hover:bg-brand-soft">
              + Add a listing
            </Link>
            <Link href="/sell/stories/new" className="rounded-xl border border-border px-4 py-2 font-medium text-brand hover:bg-brand-soft">
              + Post a story
            </Link>
          </div>
        </Card>
      ) : (
        <ul className="space-y-3">
          {orders.map((o) => {
            const s = STATUS[o.status] ?? STATUS.paid;
            return (
              <li key={o.id} className="rounded-2xl border border-border bg-card p-4">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <p className="font-medium">Order #{o.id.slice(0, 8).toUpperCase()}</p>
                    <p className="text-xs text-muted">
                      {new Date(o.created_at).toLocaleString("en-NG", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" })}
                    </p>
                  </div>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${s.tone}`}>{s.text}</span>
                </div>
                <ul className="mt-2 text-sm">
                  {o.order_items.map((i, n) => (
                    <li key={n} className="flex justify-between gap-3">
                      <span className="truncate">{i.quantity} × {i.title_snapshot}</span>
                      <span className="tabular-nums">{formatNaira(i.unit_price_kobo * i.quantity)}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-2 flex flex-wrap justify-between gap-2 border-t border-border pt-2 text-sm">
                  <span className="text-muted">{s.hint}</span>
                  <span>You receive <strong className="tabular-nums">{formatNaira(o.seller_payout_kobo)}</strong></span>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
