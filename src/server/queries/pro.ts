import "server-only";

import { PRO_ENTRY_SELECT, type ProEntry, type ProMode } from "@/lib/pro";
import { LISTING_CARD_SELECT, toListingCard, type ListingCard } from "@/server/queries/catalog";
import { createClient, createPublicClient } from "@/server/db/supabase";

const PROFILE_SELECT =
  "id, username, display_name, business_name, headline, bio, city, state, avatar_url, cover_url, is_verified, " +
  "rating_avg, rating_count, years_experience, is_available, created_at, pro_mode, pro_public, pro_published_at, " +
  "skills, languages, plan, plan_expires_at";

export type ProProfile = {
  id: string;
  username: string;
  name: string;
  displayName: string;
  businessName: string | null;
  headline: string | null;
  bio: string | null;
  city: string | null;
  state: string | null;
  avatarUrl: string | null;
  coverUrl: string | null;
  isVerified: boolean;
  ratingAvg: number | null;
  ratingCount: number;
  yearsExperience: number | null;
  isAvailable: boolean;
  memberSince: string;
  mode: ProMode | null;
  isPublic: boolean;
  skills: string[];
  languages: string[];
  isPremium: boolean;
};

type Row = {
  id: string;
  username: string;
  display_name: string;
  business_name: string | null;
  headline: string | null;
  bio: string | null;
  city: string | null;
  state: string | null;
  avatar_url: string | null;
  cover_url: string | null;
  is_verified: boolean;
  rating_avg: number | null;
  rating_count: number;
  years_experience: number | null;
  is_available: boolean;
  created_at: string;
  pro_mode: ProMode | null;
  pro_public: boolean;
  skills: string[] | null;
  languages: string[] | null;
  plan: "free" | "premium";
  plan_expires_at: string | null;
};

function toProfile(r: Row): ProProfile {
  return {
    id: r.id,
    username: r.username,
    name: r.business_name || r.display_name,
    displayName: r.display_name,
    businessName: r.business_name,
    headline: r.headline,
    bio: r.bio,
    city: r.city,
    state: r.state,
    avatarUrl: r.avatar_url,
    coverUrl: r.cover_url,
    isVerified: r.is_verified,
    ratingAvg: r.rating_avg == null ? null : Number(r.rating_avg),
    ratingCount: r.rating_count,
    yearsExperience: r.years_experience,
    isAvailable: r.is_available,
    memberSince: r.created_at,
    mode: r.pro_mode,
    isPublic: r.pro_public,
    skills: r.skills ?? [],
    languages: r.languages ?? [],
    isPremium: r.plan === "premium" && (!r.plan_expires_at || new Date(r.plan_expires_at).getTime() > Date.now()),
  };
}

export type ProPage = {
  profile: ProProfile;
  entries: ProEntry[];
  services: ListingCard[];
  hours: { day_of_week: number; opens_at: string; closes_at: string }[];
  areas: { state: string; city: string }[];
};

/**
 * Loads a professional page as the current visitor. Returns null when the
 * page doesn't exist or isn't visible to them: private pages are visible
 * only to their owner (the database applies the same rule to entries).
 */
export async function getProPage(username: string, viewerId: string | null): Promise<ProPage | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("profiles")
    .select(PROFILE_SELECT)
    .eq("username", username.toLowerCase())
    .eq("role", "seller")
    .maybeSingle();
  if (!data) return null;
  const profile = toProfile(data as unknown as Row);
  const isOwner = viewerId === profile.id;
  if (!profile.mode || (!profile.isPublic && !isOwner)) return null;

  const [{ data: entries }, { data: listings }, { data: hours }, { data: areas }] = await Promise.all([
    supabase.from("pro_entries").select(PRO_ENTRY_SELECT).eq("owner_id", profile.id).order("position"),
    supabase
      .from("listings")
      .select(LISTING_CARD_SELECT)
      .eq("seller_id", profile.id)
      .eq("status", "approved")
      .in("type", ["service", "talent"])
      .order("created_at", { ascending: false })
      .limit(12),
    supabase.from("working_hours").select("day_of_week, opens_at, closes_at").eq("seller_id", profile.id).order("day_of_week"),
    supabase.from("service_areas").select("state, city").eq("seller_id", profile.id).order("state"),
  ]);

  return {
    profile,
    entries: (entries ?? []) as ProEntry[],
    services: (listings ?? []).map(toListingCard),
    hours: hours ?? [],
    areas: areas ?? [],
  };
}

/** Title and description for link previews (WhatsApp, X, LinkedIn). Public pages only. */
export async function getProMeta(username: string) {
  const { data } = await createPublicClient()
    .from("profiles")
    .select("display_name, business_name, headline, bio, city, state, avatar_url, cover_url, pro_mode, pro_public")
    .eq("username", username.toLowerCase())
    .eq("role", "seller")
    .maybeSingle();
  if (!data || !data.pro_public || !data.pro_mode) return null;
  return {
    name: data.business_name || data.display_name,
    headline: data.headline as string | null,
    bio: data.bio as string | null,
    place: [data.city, data.state].filter(Boolean).join(", "),
    image: (data.cover_url || data.avatar_url) as string | null,
  };
}

/** Everything the editor at /sell/pro needs, for the signed-in seller. */
export async function getMyProSettings(userId: string) {
  const supabase = await createClient();
  const [{ data }, { data: entries }, { count: services }, { count: hours }, { count: areas }] = await Promise.all([
    supabase.from("profiles").select(PROFILE_SELECT).eq("id", userId).single(),
    supabase.from("pro_entries").select(PRO_ENTRY_SELECT).eq("owner_id", userId).order("position"),
    supabase
      .from("listings")
      .select("id", { count: "exact", head: true })
      .eq("seller_id", userId)
      .in("type", ["service", "talent"])
      .neq("status", "removed"),
    supabase.from("working_hours").select("seller_id", { count: "exact", head: true }).eq("seller_id", userId),
    supabase.from("service_areas").select("seller_id", { count: "exact", head: true }).eq("seller_id", userId),
  ]);
  if (!data) return null;
  return {
    profile: toProfile(data as unknown as Row),
    entries: (entries ?? []) as ProEntry[],
    serviceCount: services ?? 0,
    hasHours: (hours ?? 0) > 0,
    hasAreas: (areas ?? 0) > 0,
  };
}
