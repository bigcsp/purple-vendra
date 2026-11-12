import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PageShell } from "@/components/page-shell";
import { requireSeller } from "@/server/auth/seller";
import { createClient } from "@/server/db/supabase";
import { ProfileForm } from "./profile-form";

export const metadata: Metadata = { title: "Shop profile · Seller hub" };

export default function SellerProfilePage() {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your profile…</p>}>
        <SellerProfile />
      </Suspense>
    </PageShell>
  );
}

async function SellerProfile() {
  const user = await requireSeller("/sell/profile");
  const supabase = await createClient();
  const [{ data: p }, { data: hours }, { data: areas }] = await Promise.all([
    supabase
      .from("profiles")
      .select("business_name, headline, bio, city, state, years_experience, is_available, avatar_url")
      .eq("id", user.id)
      .single(),
    supabase.from("working_hours").select("day_of_week, opens_at, closes_at").eq("seller_id", user.id),
    supabase.from("service_areas").select("state, city").eq("seller_id", user.id).order("state"),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <Link href="/sell" className="text-sm text-muted hover:text-brand">← Seller hub</Link>
          <h1 className="text-2xl font-bold text-brand-strong">Your shop profile</h1>
          <p className="text-sm text-muted">What buyers see at the top of your shop page.</p>
        </div>
        <Link href={`/shop/${user.username}`} className="text-sm font-medium text-brand hover:underline">View my shop →</Link>
      </div>
      <ProfileForm
        userId={user.id}
        logoUrl={p?.avatar_url ?? null}
        initial={{
          businessName: p?.business_name ?? "",
          headline: p?.headline ?? "",
          bio: p?.bio ?? "",
          city: p?.city ?? "",
          state: p?.state ?? "",
          yearsExperience: p?.years_experience == null ? "" : String(p.years_experience),
          isAvailable: p?.is_available ?? true,
        }}
        hours={(hours ?? []).map((h) => ({ day: h.day_of_week, opens: String(h.opens_at).slice(0, 5), closes: String(h.closes_at).slice(0, 5) }))}
        areas={areas ?? []}
      />
    </div>
  );
}
