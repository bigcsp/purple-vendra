import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import {
  BadgeCheck,
  CalendarDays,
  Clock,
  EyeOff,
  Languages,
  MapPin,
  Pencil,
  ShieldCheck,
  Star,
  Store,
} from "lucide-react";
import { AdireField } from "@/components/adire";
import { ListingGrid } from "@/components/listing-grid";
import { MessageButton } from "@/components/messages/message-button";
import { ShareProfileButton } from "@/components/pro/share-button";
import { ReportButton } from "@/components/report-button";
import { SiteHeader } from "@/components/site-header";
import { DAYS } from "@/lib/nigeria";
import { ENTRY_KINDS, ENTRY_KIND_ORDER, proPath, yearRange, type ProEntry, type ProEntryKind } from "@/lib/pro";
import { getCurrentUser } from "@/server/auth/session";
import { getProMeta, getProPage, type ProPage } from "@/server/queries/pro";

export async function generateMetadata({ params }: PageProps<"/pro/[username]">): Promise<Metadata> {
  const { username } = await params;
  const meta = await getProMeta(decodeURIComponent(username));
  if (!meta) return { title: "Professional · Purple Shop", robots: { index: false } };
  const title = `${meta.name}${meta.headline ? ` · ${meta.headline}` : ""} | Purple Shop`;
  const description =
    meta.bio?.slice(0, 160) ||
    `Hire ${meta.name}${meta.place ? ` in ${meta.place}` : ""} on Purple Shop. Verified reviews and protected payments.`;
  return {
    title,
    description,
    alternates: { canonical: proPath(decodeURIComponent(username).toLowerCase()) },
    openGraph: { title, description, type: "profile", images: meta.image ? [meta.image] : undefined },
    twitter: { card: meta.image ? "summary_large_image" : "summary", title, description },
  };
}

export default function ProPageRoute({ params }: PageProps<"/pro/[username]">) {
  return (
    <main className="mx-auto w-full max-w-6xl flex-1 px-5 py-8">
      <SiteHeader />
      <Suspense fallback={<ProSkeleton />}>
        <Pro params={params} />
      </Suspense>
    </main>
  );
}

function ProSkeleton() {
  return (
    <div className="mt-8 animate-pulse" aria-label="Loading profile">
      <div className="aspect-[3/1] rounded-3xl bg-brand-soft/70 sm:aspect-[4/1]" />
      <div className="-mt-10 ml-6 h-24 w-24 rounded-full border-4 border-background bg-brand-soft" />
      <div className="mt-4 h-6 w-56 rounded bg-brand-soft" />
      <div className="mt-2 h-4 w-80 max-w-full rounded bg-brand-soft/70" />
    </div>
  );
}

async function Pro({ params }: { params: PageProps<"/pro/[username]">["params"] }) {
  const { username } = await params;
  const viewer = await getCurrentUser();
  const page = await getProPage(decodeURIComponent(username), viewer?.id ?? null);
  if (!page) notFound();

  const { profile: p } = page;
  const isOwner = viewer?.id === p.id;
  const creative = p.mode === "creative_space";
  const byKind = (k: ProEntryKind) => page.entries.filter((e) => e.kind === k);

  return (
    <div className="mt-8 space-y-8">
      {isOwner && (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-brand/30 bg-brand-soft px-4 py-3 text-sm">
          <span className="flex items-center gap-2 text-brand-strong">
            {!p.isPublic && <EyeOff className="h-4 w-4" aria-hidden />}
            {p.isPublic ? "This is your public page." : "Preview: your page is private. Only you can see it."}
          </span>
          <Link href="/sell/pro" className="inline-flex items-center gap-1.5 font-medium text-brand hover:underline">
            <Pencil className="h-4 w-4" aria-hidden /> Edit page
          </Link>
        </div>
      )}

      {creative ? <CreativeHero page={page} isOwner={isOwner} /> : <ProfessionalHero page={page} isOwner={isOwner} />}

      <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_320px]">
        <div className="min-w-0 space-y-8">
          {p.bio && (
            <Section title="About">
              <p className="whitespace-pre-line leading-relaxed text-foreground/90">{p.bio}</p>
            </Section>
          )}

          {page.services.length > 0 && (
            <Section title="Services" action={<Link href={`/shop/${p.username}#products`} className="text-sm font-medium text-brand hover:underline">View all</Link>}>
              <ListingGrid listings={page.services.map((l) => ({ ...l, image_path: l.image }))} saveable={!isOwner} />
            </Section>
          )}

          {ENTRY_KIND_ORDER.map((k) => {
            const list = byKind(k);
            return list.length > 0 ? (
              <Section key={k} title={ENTRY_KINDS[k].title}>
                <Timeline entries={list} />
              </Section>
            ) : null;
          })}

          {!p.bio && page.services.length === 0 && page.entries.length === 0 && (
            <p className="rounded-3xl border border-dashed border-border p-10 text-center text-sm text-muted">
              {isOwner ? "Your page is empty. Add an About, services and experience from the editor." : `${p.name} is still setting up this page.`}
            </p>
          )}
        </div>

        <aside className="space-y-6">
          {p.skills.length > 0 && (
            <SideCard title="Skills">
              <ul className="flex flex-wrap gap-2">
                {p.skills.map((s) => (
                  <li key={s} className="rounded-full bg-brand-soft px-3 py-1 text-sm font-medium text-brand">{s}</li>
                ))}
              </ul>
            </SideCard>
          )}

          {p.languages.length > 0 && (
            <SideCard title="Languages" icon={<Languages className="h-4 w-4" aria-hidden />}>
              <p className="text-sm text-foreground/90">{p.languages.join(" · ")}</p>
            </SideCard>
          )}

          {(page.hours.length > 0 || page.areas.length > 0) && (
            <SideCard title="Availability" icon={<Clock className="h-4 w-4" aria-hidden />}>
              <p className={`mb-3 inline-flex items-center gap-1.5 text-sm font-medium ${p.isAvailable ? "text-green-700" : "text-muted"}`}>
                <span className={`h-2 w-2 rounded-full ${p.isAvailable ? "bg-green-500" : "bg-gray-500"}`} />
                {p.isAvailable ? "Accepting new clients" : "Not taking new work right now"}
              </p>
              {page.hours.length > 0 && (
                <ul className="space-y-1 text-sm">
                  {DAYS.map((d, i) => {
                    const h = page.hours.find((x) => x.day_of_week === i);
                    return (
                      <li key={d} className="flex justify-between">
                        <span className="text-muted">{d}</span>
                        <span className="tabular-nums">{h ? `${String(h.opens_at).slice(0, 5)} – ${String(h.closes_at).slice(0, 5)}` : "Closed"}</span>
                      </li>
                    );
                  })}
                </ul>
              )}
              {page.areas.length > 0 && (
                <div className="mt-4 border-t border-border pt-4">
                  <p className="mb-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-muted">
                    <MapPin className="h-3.5 w-3.5" aria-hidden /> Serves
                  </p>
                  <ul className="flex flex-wrap gap-1.5 text-sm">
                    {page.areas.map((a) => (
                      <li key={`${a.state}-${a.city}`} className="rounded-full border border-border px-2.5 py-0.5">
                        {a.city === "All areas" ? `All of ${a.state}` : `${a.city}, ${a.state}`}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </SideCard>
          )}

          <SideCard title="Trust & safety" icon={<ShieldCheck className="h-4 w-4" aria-hidden />}>
            <ul className="space-y-2.5 text-sm">
              <li className="flex items-center gap-2">
                <BadgeCheck className={`h-4 w-4 ${p.isVerified ? "text-brand" : "text-muted"}`} aria-hidden />
                {p.isVerified ? "Identity verified by Purple Shop" : "Identity not yet verified"}
              </li>
              <li className="flex items-center gap-2">
                <CalendarDays className="h-4 w-4 text-muted" aria-hidden />
                Member since {new Date(p.memberSince).toLocaleDateString("en-NG", { month: "long", year: "numeric" })}
              </li>
              <li className="flex items-start gap-2">
                <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-muted" aria-hidden />
                <span>
                  Pay through Purple Shop: your money is held until the job is done.{" "}
                  <Link href="/safety" className="text-brand hover:underline">How it works</Link>
                </span>
              </li>
            </ul>
          </SideCard>

          {!isOwner && <ReportButton userId={p.id} />}
        </aside>
      </div>
    </div>
  );
}

/* ---------- Heroes ---------------------------------------------------- */

function Avatar({ p, size }: { p: ProPage["profile"]; size: string }) {
  return p.avatarUrl ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={p.avatarUrl} alt={p.name} className={`${size} shrink-0 rounded-full border-4 border-card bg-card object-cover shadow-sm`} />
  ) : (
    <span className={`${size} flex shrink-0 items-center justify-center rounded-full border-4 border-card bg-brand text-3xl font-bold text-white shadow-sm`}>
      {p.name.slice(0, 1).toUpperCase()}
    </span>
  );
}

function MetaLine({ p, light = false }: { p: ProPage["profile"]; light?: boolean }) {
  const place = [p.city, p.state].filter(Boolean).join(", ");
  const tone = light ? "text-white/85" : "text-muted";
  return (
    <p className={`flex flex-wrap items-center gap-x-4 gap-y-1 text-sm ${tone}`}>
      {place && <span className="inline-flex items-center gap-1"><MapPin className="h-4 w-4" aria-hidden />{place}</span>}
      {p.yearsExperience != null && p.yearsExperience > 0 && <span>{p.yearsExperience}+ years experience</span>}
      {p.ratingCount > 0 && p.ratingAvg != null && (
        <span className="inline-flex items-center gap-1">
          <Star className="h-4 w-4 fill-accent text-accent" aria-hidden />
          <span className={light ? "font-semibold text-white" : "font-semibold text-foreground"}>{p.ratingAvg.toFixed(1)}</span>
          ({p.ratingCount} verified review{p.ratingCount === 1 ? "" : "s"})
        </span>
      )}
    </p>
  );
}

function Actions({ p, isOwner, light = false }: { p: ProPage["profile"]; isOwner: boolean; light?: boolean }) {
  return (
    <div className="grid grid-cols-2 gap-2 sm:flex sm:flex-wrap">
      {!isOwner && <MessageButton sellerId={p.id} label="Hire me" variant="primary" className="col-span-2 sm:w-auto" />}
      <ShareProfileButton path={proPath(p.username)} name={p.name} light={light} />
      <Link
        href={`/shop/${p.username}`}
        className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 font-medium ${
          light ? "text-white hover:bg-white/10" : "text-brand hover:bg-brand-soft"
        }`}
      >
        <Store className="h-4 w-4" aria-hidden /> Shop
      </Link>
    </div>
  );
}

function ProfessionalHero({ page, isOwner }: { page: ProPage; isOwner: boolean }) {
  const p = page.profile;
  return (
    <section className="overflow-hidden rounded-3xl border border-border bg-card">
      <div className="relative aspect-[3/1] overflow-hidden bg-panel sm:aspect-[4/1]">
        {p.coverUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={p.coverUrl} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-[#3b0f6e] via-[#5b21b6] to-[#241045]">
            <AdireField className="pointer-events-none absolute -right-10 -top-10 h-[160%] w-96 opacity-40" />
          </div>
        )}
      </div>
      <div className="px-6 pb-6 sm:px-8 sm:pb-8">
        <div className="relative z-10 -mt-12 flex flex-col gap-4 sm:-mt-16 sm:flex-row sm:items-end sm:justify-between">
          <Avatar p={p} size="h-24 w-24 sm:h-32 sm:w-32" />
          <div className="hidden sm:block sm:pb-1">
            <Actions p={p} isOwner={isOwner} />
          </div>
        </div>
        <div className="mt-4">
          <h1 className="text-2xl font-bold text-brand-strong sm:text-3xl">
            {p.name}
            {p.isVerified && <BadgeCheck className="ml-2 inline-block h-6 w-6 align-[-0.2em] text-brand" aria-label="Identity verified" />}
            {p.isPremium && <span className="ml-2 inline-block rounded-full bg-accent/15 px-2.5 py-0.5 align-middle text-xs font-semibold text-accent">Premium</span>}
          </h1>
          {p.businessName && p.businessName !== p.displayName && <p className="text-sm text-muted">{p.displayName}</p>}
          {p.headline && <p className="mt-1 text-lg text-foreground/90">{p.headline}</p>}
          <div className="mt-2"><MetaLine p={p} /></div>
          <div className="mt-4 flex flex-wrap items-center gap-2">
            <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold ${
              p.isAvailable ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-700"
            }`}>
              <span className={`h-1.5 w-1.5 rounded-full ${p.isAvailable ? "bg-green-500" : "bg-gray-500"}`} />
              {p.isAvailable ? "Available for work" : "Currently unavailable"}
            </span>
            {p.skills.slice(0, 3).map((s) => (
              <span key={s} className="rounded-full border border-border px-3 py-1 text-xs font-medium text-foreground/80">{s}</span>
            ))}
          </div>
          <div className="mt-5 sm:hidden">
            <Actions p={p} isOwner={isOwner} />
          </div>
        </div>
      </div>
    </section>
  );
}

function CreativeHero({ page, isOwner }: { page: ProPage; isOwner: boolean }) {
  const p = page.profile;
  return (
    <section className="relative isolate overflow-hidden rounded-3xl bg-panel text-white">
      {p.coverUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={p.coverUrl} alt="" className="absolute inset-0 -z-10 h-full w-full object-cover" />
      ) : (
        <AdireField className="pointer-events-none absolute -right-16 -top-10 -z-10 h-[140%] w-[28rem] opacity-50 [mask-image:linear-gradient(to_left,black_55%,transparent)]" />
      )}
      <div className="absolute inset-0 -z-10 bg-gradient-to-t from-black/80 via-black/40 to-black/10" />
      <div className="flex min-h-[22rem] flex-col justify-end gap-5 px-6 pb-8 pt-24 sm:min-h-[26rem] sm:px-10 sm:pb-10">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end">
          <Avatar p={p} size="h-20 w-20 sm:h-24 sm:w-24" />
          <div className="min-w-0">
            <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
              {p.name}
              {p.isVerified && <BadgeCheck className="ml-2 inline-block h-7 w-7 align-[-0.15em] text-accent" aria-label="Identity verified" />}
            </h1>
            {p.headline && <p className="mt-1 text-lg text-white/90">{p.headline}</p>}
          </div>
        </div>
        <MetaLine p={p} light />
        <div className="flex flex-wrap items-center gap-2 text-xs font-semibold">
          <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 ${p.isAvailable ? "bg-green-500/25 text-green-50" : "bg-white/15 text-white/80"}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${p.isAvailable ? "bg-green-400" : "bg-white/60"}`} />
            {p.isAvailable ? "Accepting new clients" : "Fully booked"}
          </span>
          {p.isPremium && <span className="rounded-full bg-accent/25 px-3 py-1 text-accent">Premium</span>}
        </div>
        <Actions p={p} isOwner={isOwner} light />
      </div>
    </section>
  );
}

/* ---------- Building blocks ------------------------------------------- */

function Section({ title, action, children }: { title: string; action?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="rounded-3xl border border-border bg-card p-6 sm:p-8">
      <div className="mb-5 flex items-center justify-between gap-3">
        <h2 className="text-xl font-semibold text-brand-strong">{title}</h2>
        {action}
      </div>
      {children}
    </section>
  );
}

function SideCard({ title, icon, children }: { title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="rounded-3xl border border-border bg-card p-6">
      <h2 className="mb-3 flex items-center gap-2 font-semibold text-brand-strong">
        {icon && <span className="text-muted">{icon}</span>}
        {title}
      </h2>
      {children}
    </section>
  );
}

function Timeline({ entries }: { entries: ProEntry[] }) {
  return (
    <ol className="relative space-y-6 border-l-2 border-brand-soft pl-6">
      {entries.map((e) => (
        <li key={e.id} className="relative">
          <span className={`absolute -left-[31px] top-1.5 h-3 w-3 rounded-full ring-4 ring-card ${e.is_current ? "bg-brand" : "bg-brand/40"}`} />
          <div className="flex flex-wrap items-baseline justify-between gap-x-3">
            <h3 className="font-semibold text-foreground">{e.title}</h3>
            {yearRange(e) && <span className="text-sm tabular-nums text-muted">{yearRange(e)}</span>}
          </div>
          {(e.organisation || e.location) && (
            <p className="text-sm text-muted">{[e.organisation, e.location].filter(Boolean).join(" · ")}</p>
          )}
          {e.description && <p className="mt-2 whitespace-pre-line text-sm leading-relaxed text-foreground/85">{e.description}</p>}
        </li>
      ))}
    </ol>
  );
}
