import { cacheLife } from "next/cache";
import { createPublicClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/env";

type Category = { id: number; slug: string; name: string };

const blurbs: Record<string, string> = {
  "fashion-ade": "Tailors, Ankara and Adire, accessories",
  "art-crafts": "Paintings, prints, handmade pieces",
  "digital-design": "Logos, flyers, templates, editing",
  "photo-video-talent": "Photographers, videographers, models, MUAs",
  "tech-freelance": "Web & app devs, social media, writers, VAs",
  "home-services": "Plumbers, electricians, AC & generator repair, cleaners",
};

async function getCategories(): Promise<{ data: Category[]; error?: string }> {
  "use cache";
  cacheLife("minutes");

  if (!isSupabaseConfigured) {
    return { data: [], error: "Supabase keys are missing. Add them to .env.local." };
  }

  const { data, error } = await createPublicClient()
    .from("categories")
    .select("id, slug, name")
    .order("position");

  if (error) return { data: [], error: error.message };
  return { data: data ?? [] };
}

export default async function Home() {
  const { data: categories, error } = await getCategories();

  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <header className="flex items-center justify-between">
        <span className="text-xl font-bold text-brand">Purple Vendra</span>
        <span className="rounded-full bg-brand-soft px-3 py-1 text-xs font-medium text-brand">
          Coming soon · Nigeria
        </span>
      </header>

      <section className="mt-10 rounded-3xl bg-brand px-6 py-10 text-white sm:px-10">
        <p className="text-sm font-medium uppercase tracking-widest text-accent">
          Discover. Create. Promote. Sell.
        </p>
        <h1 className="mt-3 text-3xl font-bold leading-tight sm:text-4xl">
          Nigeria&apos;s creative marketplace
        </h1>
        <p className="mt-3 max-w-xl text-white/85">
          Buy from talented Nigerian creatives, hire freelancers, and book verified pros for home repairs. Your money is held
          safely until your order arrives.
        </p>
      </section>

      <section className="mt-10">
        <h2 className="text-lg font-semibold">Browse categories</h2>

        {error ? (
          <p className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
            Couldn&apos;t load categories: {error}
          </p>
        ) : (
          <ul className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {categories.map((c) => (
              <li
                key={c.id}
                className="rounded-2xl border border-border bg-card p-5 transition hover:border-brand"
              >
                <p className="font-semibold text-brand-strong">{c.name}</p>
                <p className="mt-1 text-sm text-muted">{blurbs[c.slug] ?? ""}</p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
