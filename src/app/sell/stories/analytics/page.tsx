import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { SiteHeader } from "@/components/site-header";
import { Card } from "@/components/ui";
import { formatNaira } from "@/lib/money";
import { requireSeller } from "@/lib/seller";
import { STORY_STATUS } from "@/lib/stories";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Story analytics · Purple Vendra" };

const PERIODS = [7, 30, 90] as const;

type Row = {
  video_id: string;
  title: string;
  status: string;
  impressions: number;
  views: number;
  likes: number;
  comments: number;
  shares: number;
  product_clicks: number;
  shop_visits: number;
  add_to_carts: number;
  orders: number;
  sales_kobo: number;
};

export default function AnalyticsPage({ searchParams }: PageProps<"/sell/stories/analytics">) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<p className="mt-10 text-sm text-muted">Loading analytics…</p>}>
        <Analytics searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Analytics({ searchParams }: { searchParams: PageProps<"/sell/stories/analytics">["searchParams"] }) {
  await requireSeller("/sell/stories/analytics");
  const { days: daysParam } = await searchParams;
  const days = PERIODS.find((p) => String(p) === daysParam) ?? 30;
  const supabase = await createClient();
  const [{ data: storyData }, { data: campaignData }] = await Promise.all([
    supabase.rpc("get_story_analytics", { p_days: days }),
    supabase.rpc("get_campaign_analytics"),
  ]);
  const rows = ((storyData ?? []) as Row[]).map((r) =>
    Object.fromEntries(Object.entries(r).map(([k, v]) => [k, typeof v === "string" && /^\d+$/.test(v) ? Number(v) : v])),
  ) as Row[];
  const sum = (k: keyof Row) => rows.reduce((t, r) => t + Number(r[k] ?? 0), 0);

  const views = sum("views");
  const engagement = sum("likes") + sum("comments") + sum("shares");
  const engagementRate = views ? (engagement / views) * 100 : 0;
  const campaigns = (campaignData ?? []) as { status: string; impressions: number; views: number; sales_kobo: number }[];
  const running = campaigns.filter((c) => c.status === "active").length;

  const tiles: { label: string; value: string; hint?: string }[] = [
    { label: "Views", value: views.toLocaleString() },
    { label: "Engagement", value: engagement.toLocaleString(), hint: views ? `${engagementRate.toFixed(1)}% of views` : undefined },
    { label: "Likes", value: sum("likes").toLocaleString() },
    { label: "Comments", value: sum("comments").toLocaleString() },
    { label: "Shares", value: sum("shares").toLocaleString() },
    { label: "Product clicks", value: sum("product_clicks").toLocaleString() },
    { label: "Shop visits", value: sum("shop_visits").toLocaleString() },
    { label: "Added to cart", value: sum("add_to_carts").toLocaleString() },
    { label: "Sales from videos", value: formatNaira(sum("sales_kobo")), hint: `${sum("orders")} orders` },
    {
      label: "Campaigns",
      value: `${running} running`,
      hint: `${campaigns.reduce((t, c) => t + Number(c.impressions), 0).toLocaleString()} promoted impressions`,
    },
  ];

  return (
    <div className="mt-10 space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <Link href="/sell/stories" className="text-sm text-muted hover:text-brand">← Vendra Stories</Link>
          <h1 className="text-2xl font-bold text-brand-strong">Story analytics</h1>
        </div>
        <nav className="flex rounded-xl border border-border bg-white p-1 text-sm" aria-label="Time range">
          {PERIODS.map((p) => (
            <Link key={p} href={`/sell/stories/analytics?days=${p}`}
              className={`rounded-lg px-3 py-1.5 ${p === days ? "bg-brand text-white" : "text-brand hover:bg-brand-soft"}`}>
              {p} days
            </Link>
          ))}
        </nav>
      </div>

      <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {tiles.map((t) => (
          <li key={t.label} className="rounded-2xl border border-border bg-card p-4">
            <p className="text-xs text-muted">{t.label}</p>
            <p className="mt-1 text-2xl font-semibold tabular-nums text-foreground">{t.value}</p>
            {t.hint && <p className="mt-0.5 text-xs text-muted">{t.hint}</p>}
          </li>
        ))}
      </ul>

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">By story · last {days} days</h2>
        {rows.length === 0 ? (
          <p className="mt-1 text-sm text-muted">Post a story to start seeing numbers here.</p>
        ) : (
          <div className="mt-3 overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="text-left text-xs text-muted">
                <tr>
                  {["Story", "Views", "Likes", "Comments", "Shares", "Product clicks", "Shop visits", "Carts", "Sales"].map((h, i) => (
                    <th key={h} className={`py-2 pr-3 font-medium ${i ? "text-right" : ""}`}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((r) => {
                  const s = STORY_STATUS[r.status] ?? STORY_STATUS.draft;
                  return (
                    <tr key={r.video_id}>
                      <td className="max-w-56 py-2 pr-3">
                        <Link href={`/sell/stories/${r.video_id}`} className="block truncate hover:text-brand">{r.title}</Link>
                        <span className={`rounded-full px-1.5 text-[10px] ${s.tone}`}>{s.text}</span>
                      </td>
                      {[r.views, r.likes, r.comments, r.shares, r.product_clicks, r.shop_visits, r.add_to_carts].map((v, i) => (
                        <td key={i} className="py-2 pr-3 text-right tabular-nums">{Number(v).toLocaleString()}</td>
                      ))}
                      <td className="py-2 pr-3 text-right tabular-nums">{formatNaira(r.sales_kobo)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
        <p className="mt-3 text-xs text-muted">
          Views count once per viewer session, and your own views aren&apos;t counted. Sales are paid orders of products tagged
          in a story, within 7 days of the buyer adding them to cart from that story. They start counting when checkout
          launches. <Link href="/sell/stories/promote" className="text-brand underline">See campaign results →</Link>
        </p>
      </Card>
    </div>
  );
}
