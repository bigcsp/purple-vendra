import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { ArrowRight, CircleCheck, CircleDashed, Crown, Pencil } from "lucide-react";
import { PageShell } from "@/components/page-shell";
import { ENTRY_KIND_ORDER, PRO_MODES, profileStrength } from "@/lib/pro";
import { requireSeller } from "@/server/auth/seller";
import { getMyProSettings } from "@/server/queries/pro";
import { EntrySection } from "./entry-section";
import { ModeChooser } from "./mode-chooser";
import { CoverCard, SkillsCard, VisibilityCard } from "./pro-settings";

export const metadata: Metadata = { title: "Professional page · Seller hub" };

export default function ProEditorPage({ searchParams }: PageProps<"/sell/pro">) {
  return (
    <PageShell wide>
      <Suspense fallback={<EditorSkeleton />}>
        <ProEditor searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

function EditorSkeleton() {
  return (
    <div className="animate-pulse space-y-4" aria-label="Loading your professional page">
      <div className="h-8 w-64 rounded-lg bg-brand-soft" />
      <div className="h-40 rounded-3xl bg-brand-soft/60" />
      <div className="h-64 rounded-3xl bg-brand-soft/60" />
    </div>
  );
}

async function ProEditor({ searchParams }: { searchParams: PageProps<"/sell/pro">["searchParams"] }) {
  const user = await requireSeller("/sell/pro");
  const [settings, { change }] = await Promise.all([getMyProSettings(user.id), searchParams]);
  if (!settings) return <p className="text-sm text-muted">We couldn&apos;t load your profile. Please refresh.</p>;
  const { profile: p, entries } = settings;

  // First visit (or switching): choose the page type.
  if (!p.mode || change === "type") {
    return (
      <div className="space-y-8">
        <div>
          <Link href={p.mode ? "/sell/pro" : "/sell"} className="text-sm text-muted hover:text-brand">
            ← {p.mode ? "Professional page" : "Seller hub"}
          </Link>
          <h1 className="mt-1 text-2xl font-bold text-brand-strong sm:text-3xl">
            {p.mode ? "Change your page type" : "Create your professional page"}
          </h1>
          <p className="mt-1 max-w-2xl text-muted">
            Give customers one link that shows who you are, what you do and how to hire you. Choose the style that fits
            your work.
          </p>
        </div>
        <ModeChooser current={p.mode} />
      </div>
    );
  }

  const counts = Object.fromEntries(ENTRY_KIND_ORDER.map((k) => [k, entries.filter((e) => e.kind === k).length]));
  const strength = profileStrength({
    hasPhoto: !!p.avatarUrl,
    hasCover: !!p.coverUrl,
    headline: p.headline,
    bio: p.bio,
    hasLocation: !!(p.city || p.state),
    skills: p.skills.length,
    entries: counts,
    services: settings.serviceCount,
    hasHours: settings.hasHours,
  });
  const todo = strength.items.filter((i) => !i.done);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <Link href="/sell" className="text-sm text-muted hover:text-brand">← Seller hub</Link>
          <h1 className="mt-1 text-2xl font-bold text-brand-strong sm:text-3xl">Professional page</h1>
          <p className="text-sm text-muted">
            {PRO_MODES[p.mode].title} ·{" "}
            <Link href="/sell/pro?change=type" className="font-medium text-brand hover:underline">Change type</Link>
          </p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <div className="min-w-0 space-y-6">
          <VisibilityCard username={p.username} isPublic={p.isPublic} />
          <CoverCard userId={p.id} coverUrl={p.coverUrl} />

          {/* Shared with the shop profile: edited in one place. */}
          <section className="rounded-3xl border border-border bg-card p-6 sm:p-8">
            <div className="flex items-start justify-between gap-3">
              <div className="flex min-w-0 items-center gap-4">
                {p.avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={p.avatarUrl} alt="" className="h-14 w-14 shrink-0 rounded-full object-cover" />
                ) : (
                  <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-brand-soft text-xl font-bold text-brand">
                    {p.name.slice(0, 1).toUpperCase()}
                  </span>
                )}
                <div className="min-w-0">
                  <p className="truncate font-semibold text-foreground">{p.name}</p>
                  <p className="truncate text-sm text-muted">{p.headline || "No headline yet"}</p>
                  <p className="text-xs text-muted">
                    {[p.city, p.state].filter(Boolean).join(", ") || "No location"} ·{" "}
                    {p.isAvailable ? "Available for work" : "Not taking work"}
                  </p>
                </div>
              </div>
              <Link href="/sell/profile" className="inline-flex shrink-0 items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm font-medium text-brand hover:bg-brand-soft">
                <Pencil className="h-4 w-4" aria-hidden /> Edit
              </Link>
            </div>
            <p className="mt-4 text-xs text-muted">
              Photo, name, headline, about, location, availability, working hours and service areas are shared with your
              shop, so you only edit them once.
            </p>
          </section>

          <SkillsCard skills={p.skills} languages={p.languages} />
          {ENTRY_KIND_ORDER.map((kind) => (
            <EntrySection key={kind} kind={kind} entries={entries.filter((e) => e.kind === kind)} />
          ))}

          <section className="rounded-3xl border border-border bg-card p-6 sm:p-8">
            <h2 className="text-lg font-semibold text-brand-strong">Services</h2>
            <p className="mt-1 text-sm text-muted">
              {settings.serviceCount > 0
                ? `You have ${settings.serviceCount} service listing${settings.serviceCount === 1 ? "" : "s"}. Live ones appear on your page with prices or “Get a quote”.`
                : "Add a service listing with a starting price or “Quote on request”. It appears on your page and in search."}
            </p>
            <div className="mt-4 flex flex-wrap gap-2">
              <Link href="/sell/listings/new" className="rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">
                Add a service
              </Link>
              <Link href="/sell/listings" className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
                Manage listings
              </Link>
            </div>
          </section>
        </div>

        <aside className="space-y-6 lg:sticky lg:top-6 lg:self-start">
          <section className="rounded-3xl border border-border bg-card p-6">
            <div className="flex items-baseline justify-between">
              <h2 className="font-semibold text-brand-strong">Profile strength</h2>
              <span className="text-2xl font-bold tabular-nums text-brand">{strength.score}%</span>
            </div>
            <div className="mt-3 h-2 overflow-hidden rounded-full bg-brand-soft" role="progressbar" aria-valuenow={strength.score} aria-valuemin={0} aria-valuemax={100}>
              <div className="h-full rounded-full bg-brand transition-all" style={{ width: `${strength.score}%` }} />
            </div>
            {todo.length === 0 ? (
              <p className="mt-4 flex items-center gap-2 text-sm text-green-700">
                <CircleCheck className="h-4 w-4" aria-hidden /> Your page is complete.
              </p>
            ) : (
              <ul className="mt-4 space-y-2 text-sm">
                {strength.items.map((i) => (
                  <li key={i.label}>
                    {i.done ? (
                      <span className="flex items-center gap-2 text-muted line-through decoration-muted/50">
                        <CircleCheck className="h-4 w-4 shrink-0 text-green-700" aria-hidden /> {i.label}
                      </span>
                    ) : (
                      <a href={i.href} className="group flex items-center gap-2 text-foreground hover:text-brand">
                        <CircleDashed className="h-4 w-4 shrink-0 text-muted group-hover:text-brand" aria-hidden />
                        <span className="flex-1">{i.label}</span>
                        <ArrowRight className="h-3.5 w-3.5 opacity-0 transition group-hover:opacity-100" aria-hidden />
                      </a>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section className="rounded-3xl border border-border bg-card p-6">
            <div className="flex items-center gap-2">
              <Crown className="h-4 w-4 text-accent" aria-hidden />
              <h2 className="font-semibold text-brand-strong">{p.isPremium ? "Premium" : "Free plan"}</h2>
            </div>
            <p className="mt-1 text-sm text-muted">
              {p.isPremium
                ? "Your Premium features are active."
                : "Your professional page is free. Premium adds extra themes, unlimited projects, personal website links and a Premium badge."}
            </p>
            {!p.isPremium && <p className="mt-3 text-xs text-muted">Premium opens when payments go live.</p>}
          </section>
        </aside>
      </div>
    </div>
  );
}
