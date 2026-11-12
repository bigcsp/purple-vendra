"use server";

import { revalidatePath } from "next/cache";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/server/db/supabase";

type Result = { ok?: true; error?: string };

async function me() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return { supabase, user };
}

function friendly(message: string) {
  if (/2FA|row-level security/i.test(message)) return "Not allowed. Make sure you're signed in with your 2FA code.";
  if (/headline_check/.test(message)) return "Headline: up to 80 characters.";
  if (/bio_check/.test(message)) return "About: up to 500 characters.";
  if (/business_name_check/.test(message)) return "Business name: up to 80 characters.";
  return message;
}

const isState = (s: string) => (NIGERIAN_STATES as readonly string[]).includes(s);

export type ProfileInput = {
  businessName: string;
  headline: string;
  bio: string;
  city: string;
  state: string;
  yearsExperience: string;
  isAvailable: boolean;
};

export async function updateProfile(input: ProfileInput): Promise<Result> {
  const { supabase, user } = await me();
  if (!user) return { error: "Please sign in again." };
  const years = input.yearsExperience.trim() === "" ? null : Number(input.yearsExperience);
  if (years !== null && (!Number.isInteger(years) || years < 0 || years > 80)) return { error: "Years of experience: 0–80." };
  if (input.state && !isState(input.state)) return { error: "Choose a state from the list." };

  const { error } = await supabase
    .from("profiles")
    .update({
      business_name: input.businessName.trim().slice(0, 80) || null,
      headline: input.headline.trim().slice(0, 80) || null,
      bio: input.bio.trim().slice(0, 500) || null,
      city: input.city.trim().slice(0, 80) || null,
      state: input.state || null,
      years_experience: years,
      is_available: input.isAvailable,
    })
    .eq("id", user.id);
  if (error) return { error: friendly(error.message) };
  revalidatePath("/sell/profile");
  return { ok: true };
}

export async function setLogo(path: string): Promise<Result> {
  const { supabase, user } = await me();
  if (!user) return { error: "Please sign in again." };
  if (!path.startsWith(`${user.id}/profile/`)) return { error: "Upload the picture first." };

  const { data: current } = await supabase.from("profiles").select("avatar_url").eq("id", user.id).single();
  const { error } = await supabase.from("profiles").update({ avatar_url: publicFileUrl("listing-images", path) }).eq("id", user.id);
  if (error) return { error: friendly(error.message) };

  // Remove the previous logo file if it was one of ours.
  const marker = "/object/public/listing-images/";
  const old = current?.avatar_url?.includes(marker) ? decodeURIComponent(current.avatar_url.split(marker)[1]) : null;
  if (old && old !== path && old.startsWith(`${user.id}/profile/`)) {
    await supabase.storage.from("listing-images").remove([old]);
  }
  revalidatePath("/sell/profile");
  return { ok: true };
}

export type HoursRow = { day: number; opens: string; closes: string };

export async function saveWorkingHours(rows: HoursRow[]): Promise<Result> {
  const { supabase, user } = await me();
  if (!user) return { error: "Please sign in again." };
  const time = /^([01]\d|2[0-3]):[0-5]\d$/;
  for (const r of rows) {
    if (!Number.isInteger(r.day) || r.day < 0 || r.day > 6) return { error: "Invalid day." };
    if (!time.test(r.opens) || !time.test(r.closes)) return { error: "Use times like 09:00." };
    if (r.closes <= r.opens) return { error: "Closing time must be after opening time." };
  }
  const { error: delError } = await supabase.from("working_hours").delete().eq("seller_id", user.id);
  if (delError) return { error: friendly(delError.message) };
  if (rows.length) {
    const { error } = await supabase
      .from("working_hours")
      .insert(rows.map((r) => ({ seller_id: user.id, day_of_week: r.day, opens_at: r.opens, closes_at: r.closes })));
    if (error) return { error: friendly(error.message) };
  }
  revalidatePath("/sell/profile");
  return { ok: true };
}

export async function addServiceArea(state: string, city: string): Promise<Result> {
  const { supabase, user } = await me();
  if (!user) return { error: "Please sign in again." };
  if (!isState(state)) return { error: "Choose a state." };
  const area = city.trim().slice(0, 80) || "All areas";
  const { error } = await supabase.from("service_areas").insert({ seller_id: user.id, state, city: area });
  if (error) {
    if (error.code === "23505") return { error: "You already serve that area." };
    return { error: friendly(error.message) };
  }
  revalidatePath("/sell/profile");
  return { ok: true };
}

export async function removeServiceArea(state: string, city: string): Promise<Result> {
  const { supabase, user } = await me();
  if (!user) return { error: "Please sign in again." };
  const { error } = await supabase.from("service_areas").delete().eq("seller_id", user.id).eq("state", state).eq("city", city);
  if (error) return { error: friendly(error.message) };
  revalidatePath("/sell/profile");
  return { ok: true };
}
