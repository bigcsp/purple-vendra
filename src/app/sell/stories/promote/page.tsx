import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";
import { getCategories } from "@/lib/catalog";
import { formatNaira } from "@/lib/money";
import { requireSeller } from "@/lib/seller";
import { publicFileUrl } from "@/lib/storage-url";
import { CAMPAIGN_STATUS } from "@/lib/stories";
import { createClient } from "@/lib/supabase/server";
import { CampaignActions } from "./campaign-actions";
import { CampaignForm } from "./campaign-form";

export const metadata: Metadata = { title: "Promote a story · Purple Vendra" };

export default function PromotePage({ searchParams }: PageProps<"/sell/stories/promote">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading…</p>}>
        <Promote searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

type CampaignRow = {
  campaign_id: string;
  video_title: string;
  status: string;
  budget_kobo: number;
  duration_days: number;
  starts_at: string | null;
  ends_at: string | null;
  impressions: number;
  views: number;
  product_clicks: number;
  shop_visits: number;
  add_to_carts: number;
  orders: number;
  sales_kobo: number;
};

const date = (d: string | null) => (d ? new Date(d).toLocaleDateString("en-NG", { day: "numeric", month: "short" }) : "–");

async function Promote({ searchParams }: { searchParams: PageProps<"/sell/stories/promote">["searchParams"] }) {
  const user = await requireSeller("/sell/stories/promote");
  const { video } = await searchParams;
  const supabase = await createClient();
  const [{ data: videos }, categories, { data: campaigns }] = await Promise.all([
    supabase
      .from("story_videos")
      .select("id, title, thumbnail_path")
      .eq("seller_id", user.id)
      .eq("status", "published")
      .order("published_at", { ascending: false }),
    getCategories(),
    supabase.rpc("get_campaign_analytics"),
  ]);
  const rows = (campaigns ?? []) as CampaignRow[];

  return (
    <div className="space-y-6">
      <div>
        <Link href="/sell/stories" className="text-sm text-muted hover:text-brand">← Vendra Stories</Link>
        <h1 className="text-2xl font-bold text-brand-strong">Promote a story</h1>
        <p className="text-sm text-muted">Put your best video in front of more buyers.</p>
      </div>

      <Card>
        <CampaignForm
          videos={(videos ?? []).map((v) => ({ id: v.id, title: v.title, poster: publicFileUrl("story-media", v.thumbnail_path) }))}
          categories={categories.map((c) => ({ id: c.id, name: c.name }))}
          initialVideo={typeof video === "string" ? video : undefined}
        />
      </Card>

      <Card>
        <h2 className="text-lg font-semibold text-brand-strong">Your campaigns</h2>
        {rows.length === 0 ? (
          <p className="mt-1 text-sm text-muted">No campaigns yet.</p>
        ) : (
          <div className="mt-3 overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <thead className="text-left text-xs text-muted">
                <tr>
                  <th className="py-2 pr-3 font-medium">Story</th>
                  <th className="py-2 pr-3 font-medium">Status</th>
                  <th className="py-2 pr-3 font-medium">Budget</th>
                  <th className="py-2 pr-3 font-medium">Dates</th>
                  <th className="py-2 pr-3 text-right font-medium">Seen</th>
                  <th className="py-2 pr-3 text-right font-medium">Views</th>
                  <th className="py-2 pr-3 text-right font-medium">Clicks</th>
                  <th className="py-2 pr-3 text-right font-medium">Carts</th>
                  <th className="py-2 pr-3 text-right font-medium">Sales</th>
                  <th className="py-2 font-medium" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((c) => {
                  const s = CAMPAIGN_STATUS[c.status] ?? CAMPAIGN_STATUS.awaiting_payment;
                  return (
                    <tr key={c.campaign_id}>
                      <td className="max-w-40 truncate py-2 pr-3">{c.video_title}</td>
                      <td className="py-2 pr-3"><span className={`rounded-full px-2 py-0.5 text-xs ${s.tone}`}>{s.text}</span></td>
                      <td className="py-2 pr-3">{formatNaira(c.budget_kobo)} · {c.duration_days}d</td>
                      <td className="py-2 pr-3 text-xs text-muted">{c.starts_at ? `${date(c.starts_at)} – ${date(c.ends_at)}` : "Starts after payment"}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">{c.impressions}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">{c.views}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">{Number(c.product_clicks) + Number(c.shop_visits)}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">{c.add_to_carts}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">{formatNaira(c.sales_kobo)}</td>
                      <td className="py-2"><CampaignActions id={c.campaign_id} status={c.status} /></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <p className="mt-2 text-xs text-muted">
              Seen = shown in the feed · Clicks = product taps + shop visits · Sales = paid orders of tagged products within 7
              days of adding them to cart from this campaign (starts counting when checkout launches).
            </p>
          </div>
        )}
      </Card>
    </div>
  );
}
