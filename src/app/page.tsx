import { cacheLife } from "next/cache";
import { createPublicClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";
import Link from "next/link";
import { SiteHeader } from "@/components/site-header";

type Category = { id: number; slug: string; name: string };
type Section = {
  id: number;
  slug: string;
  name: string;
  tagline: string;
  categories: Category[];
};

const blurbs: Record<string, string> = {
  "fashion-adire": "Tailors, Ankara and Adire, accessories",
  "art-crafts": "Paintings, prints, handmade pieces",
  "digital-design": "Logos, flyers, templates, editing",
  "photo-video-talent": "Photographers, videographers, models, MUAs",
  "tech-freelance": "Web & app devs, social media, writers, VAs",
  "home-services": "Plumbers, electricians, AC & generator repair, cleaners",
};

async function getSections(): Promise<{ data: Section[]; error?: string }> {
  "use cache";
  cacheLife("minutes");

  if (!isSupabaseConfigured) {
    return { data: [], error: "Supabase keys are missing. Add them to .env.local." };
  }

  const { data, error } = await createPublicClient()
    .from("sections")
    .select("id, slug, name, tagline, categories(id, slug, name)")
    .order("position")
    .order("position", { referencedTable: "categories" });

  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as Section[] };
}

export default async function Home() {
  const { data: sections, error } = await getSections();

  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />

      <section className="mt-10 rounded-3xl bg-brand px-6 py-10 text-white sm:px-10">
        <p className="text-sm font-medium uppercase tracking-widest text-accent">
          Discover. Create. Promote. Sell.
        </p>
        <h1 className="mt-3 text-3xl font-bold leading-tight sm:text-4xl">
          Turn your skills into a business people can find
        </h1>
        <p className="mt-3 max-w-xl text-white/85">
          Shop from Nigerian creatives, hire freelancers, and book verified pros for
          home repairs. Your money is held safely until the job is done.
        </p>
      </section>

      <Link
        href="/stories"
        className="mt-6 flex items-center justify-between gap-4 rounded-3xl border border-border bg-card p-5 transition hover:border-brand"
      >
        <span>
          <span className="block text-xs font-semibold uppercase tracking-widest text-accent">Vendra Stories</span>
          <span className="block text-lg font-semibold text-brand-strong">Watch makers at work, then shop what you see</span>
        </span>
        <span className="shrink-0 rounded-full bg-brand px-4 py-2 text-sm font-medium text-white">Watch →</span>
      </Link>

      {error ? (
        <p className="mt-10 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          Couldn&apos;t load the marketplaces: {error}
        </p>
      ) : (
        sections.map((s) => (
          <section key={s.id} className="mt-12">
            <h2 className="text-xl font-semibold text-brand-strong">{s.name}</h2>
            <p className="mt-1 text-sm text-muted">{s.tagline}</p>

            <ul className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {s.categories.map((c) => (
                <li
                  key={c.id}
                  className="rounded-2xl border border-border bg-card p-5 transition hover:border-brand"
                >
                  <p className="font-semibold text-brand-strong">{c.name}</p>
                  <p className="mt-1 text-sm text-muted">{blurbs[c.slug] ?? ""}</p>
                </li>
              ))}
            </ul>
          </section>
        ))
      )}

      <p className="mt-14 text-center text-sm text-muted">
        One account · verified reviews · safe escrow checkout · built-in promotion
      </p>
    </main>
  );
}
