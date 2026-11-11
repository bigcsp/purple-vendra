import "server-only";

import { createClient } from "@/lib/supabase/server";

export type Category = { id: number; slug: string; name: string; section: string };

export const LISTING_TYPES = { product: "Product", service: "Service", talent: "Talent" } as const;
export const DELIVERY_MODES = {
  delivery: "Delivery",
  pickup: "Pickup",
  digital: "Digital download",
  in_person_service: "In-person service",
  remote_service: "Remote service",
} as const;
export const LISTING_STATUS: Record<string, { text: string; tone: string }> = {
  draft: { text: "Draft", tone: "bg-gray-100 text-gray-700" },
  pending: { text: "Under review", tone: "bg-amber-100 text-amber-800" },
  approved: { text: "Live", tone: "bg-green-100 text-green-800" },
  rejected: { text: "Needs changes", tone: "bg-red-100 text-red-700" },
  removed: { text: "Removed", tone: "bg-gray-100 text-gray-500" },
};

export async function getCategories(): Promise<Category[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("categories")
    .select("id, slug, name, position, sections(name, position)")
    .order("position");
  type Row = { id: number; slug: string; name: string; sections: { name: string; position: number } | null };
  return ((data ?? []) as unknown as Row[])
    .sort((a, b) => (a.sections?.position ?? 0) - (b.sections?.position ?? 0))
    .map((c) => ({ id: c.id, slug: c.slug, name: c.name, section: c.sections?.name ?? "" }));
}

export type ListingCard = {
  id: string;
  title: string;
  price_kobo: number;
  price_is_starting: boolean;
  quote_on_request: boolean;
  status: string;
  image: string | null;
};

type ListingRow = {
  id: string;
  title: string;
  price_kobo: number;
  price_is_starting: boolean;
  quote_on_request: boolean;
  status: string;
  listing_images: { storage_path: string; position: number }[] | null;
};

export function toListingCard(l: ListingRow): ListingCard {
  const first = [...(l.listing_images ?? [])].sort((a, b) => a.position - b.position)[0];
  return {
    id: l.id,
    title: l.title,
    price_kobo: l.price_kobo,
    price_is_starting: l.price_is_starting,
    quote_on_request: l.quote_on_request,
    status: l.status,
    image: first?.storage_path ?? null,
  };
}

export const LISTING_CARD_SELECT =
  "id, title, price_kobo, price_is_starting, quote_on_request, status, listing_images(storage_path, position)";
