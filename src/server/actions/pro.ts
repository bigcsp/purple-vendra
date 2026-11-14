"use server";

import { revalidatePath } from "next/cache";
import { ENTRY_KINDS, PRO_LIMITS, type ProEntryKind, type ProMode } from "@/lib/pro";
import { publicFileUrl } from "@/lib/storage-url";
import { createClient } from "@/server/db/supabase";

/*
 * Purple Pro: editing a professional page. Every rule here is ALSO enforced
 * by the database (migration 022), so these checks are for friendly
 * messages, not security.
 */

type Result = { ok?: true; error?: string };

async function me() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, username: null };
  const { data } = await supabase.from("profiles").select("username").eq("id", user.id).single();
  return { supabase, user, username: data?.username ?? null };
}

function friendly(message: string, code?: string) {
  if (/2FA|row-level security/i.test(message)) return "Not allowed. Make sure you're signed in with your 2FA code.";
  if (/skills_check/.test(message)) return `Skills: up to ${PRO_LIMITS.skills}, each up to ${PRO_LIMITS.skillLength} characters, no repeats.`;
  if (/languages_check/.test(message)) return `Languages: up to ${PRO_LIMITS.languages}, no repeats.`;
  if (/pro_entries_check/.test(message)) return "Check the years: the end year can't be before the start year.";
  if (/pro_entries_title_check/.test(message)) return "Add a title (up to 120 characters).";
  if (code === "54000") return message;
  return message;
}

function refresh(username: string | null) {
  revalidatePath("/sell/pro");
  if (username) revalidatePath(`/pro/${username}`);
}

export async function choosePageType(mode: ProMode): Promise<Result> {
  if (mode !== "professional" && mode !== "creative_space") return { error: "Choose a page type." };
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  const { error } = await supabase.from("profiles").update({ pro_mode: mode }).eq("id", user.id);
  if (error) return { error: friendly(error.message) };
  refresh(username);
  return { ok: true };
}

export async function setProVisibility(isPublic: boolean): Promise<Result> {
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  const { error } = await supabase.from("profiles").update({ pro_public: isPublic }).eq("id", user.id);
  if (error) return { error: friendly(error.message) };
  refresh(username);
  return { ok: true };
}

function cleanTags(list: string[], max: number, maxLen: number, label: string): string[] | string {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of list) {
    const t = raw.replace(/\s+/g, " ").trim();
    if (!t) continue;
    if (t.length > maxLen) return `${label}: "${t.slice(0, 20)}…" is too long (max ${maxLen} characters).`;
    if (seen.has(t.toLowerCase())) continue;
    seen.add(t.toLowerCase());
    out.push(t);
  }
  if (out.length > max) return `${label}: up to ${max}.`;
  return out;
}

export async function saveSkillsAndLanguages(skills: string[], languages: string[]): Promise<Result> {
  const s = cleanTags(skills, PRO_LIMITS.skills, PRO_LIMITS.skillLength, "Skills");
  if (typeof s === "string") return { error: s };
  const l = cleanTags(languages, PRO_LIMITS.languages, PRO_LIMITS.languageLength, "Languages");
  if (typeof l === "string") return { error: l };
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  const { error } = await supabase.from("profiles").update({ skills: s, languages: l }).eq("id", user.id);
  if (error) return { error: friendly(error.message) };
  refresh(username);
  return { ok: true };
}

const MARKER = "/object/public/listing-images/";

export async function setCover(path: string | null): Promise<Result> {
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  if (path !== null && !path.startsWith(`${user.id}/profile/cover-`)) return { error: "Upload the picture first." };

  const { data: current } = await supabase.from("profiles").select("cover_url").eq("id", user.id).single();
  const { error } = await supabase
    .from("profiles")
    .update({ cover_url: path ? publicFileUrl("listing-images", path) : null })
    .eq("id", user.id);
  if (error) return { error: friendly(error.message) };

  // Remove the previous cover file if it was one of ours.
  const old = current?.cover_url?.includes(MARKER) ? decodeURIComponent(current.cover_url.split(MARKER)[1]) : null;
  if (old && old !== path && old.startsWith(`${user.id}/profile/cover-`)) {
    await supabase.storage.from("listing-images").remove([old]);
  }
  refresh(username);
  return { ok: true };
}

export type EntryInput = {
  id?: string;
  kind: ProEntryKind;
  title: string;
  organisation: string;
  location: string;
  startYear: string;
  endYear: string;
  isCurrent: boolean;
  description: string;
};

function year(v: string): number | null | "bad" {
  const t = v.trim();
  if (!t) return null;
  const n = Number(t);
  const max = new Date().getFullYear() + 10;
  return Number.isInteger(n) && n >= 1950 && n <= max ? n : "bad";
}

export async function saveEntry(input: EntryInput): Promise<Result & { id?: string }> {
  if (!(input.kind in ENTRY_KINDS)) return { error: "Unknown section." };
  const title = input.title.trim();
  if (!title) return { error: `Add the ${ENTRY_KINDS[input.kind].titleLabel.toLowerCase()}.` };
  if (title.length > 120) return { error: "Title: up to 120 characters." };
  if (input.organisation.trim().length > 120) return { error: "Organisation: up to 120 characters." };
  if (input.location.trim().length > 80) return { error: "Location: up to 80 characters." };
  if (input.description.trim().length > 1000) return { error: "Description: up to 1,000 characters." };
  const start = year(input.startYear);
  const end = input.isCurrent ? null : year(input.endYear);
  if (start === "bad" || end === "bad") return { error: "Use a 4-digit year, like 2021." };
  if (start && end && end < start) return { error: "The end year can't be before the start year." };

  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };

  const row = {
    title,
    organisation: input.organisation.trim() || null,
    location: input.location.trim() || null,
    start_year: start,
    end_year: end,
    is_current: input.isCurrent,
    description: input.description.trim() || null,
  };

  if (input.id) {
    const { error } = await supabase.from("pro_entries").update(row).eq("id", input.id).eq("owner_id", user.id);
    if (error) return { error: friendly(error.message, error.code) };
    refresh(username);
    return { ok: true, id: input.id };
  }

  // New items go to the top of their section.
  const { data: first } = await supabase
    .from("pro_entries")
    .select("position")
    .eq("owner_id", user.id)
    .eq("kind", input.kind)
    .order("position", { ascending: true })
    .limit(1)
    .maybeSingle();
  const { data, error } = await supabase
    .from("pro_entries")
    .insert({ ...row, owner_id: user.id, kind: input.kind, position: (first?.position ?? 1) - 1 })
    .select("id")
    .single();
  if (error) return { error: friendly(error.message, error.code) };
  refresh(username);
  return { ok: true, id: data.id };
}

export async function deleteEntry(id: string): Promise<Result> {
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  const { error } = await supabase.from("pro_entries").delete().eq("id", id).eq("owner_id", user.id);
  if (error) return { error: friendly(error.message) };
  refresh(username);
  return { ok: true };
}

/** Saves a section's order (ids top to bottom). */
export async function reorderEntries(kind: ProEntryKind, ids: string[]): Promise<Result> {
  if (!(kind in ENTRY_KINDS) || ids.length > PRO_LIMITS.entriesPerSection) return { error: "Invalid order." };
  const { supabase, user, username } = await me();
  if (!user) return { error: "Please sign in again." };
  const results = await Promise.all(
    ids.map((id, i) =>
      supabase.from("pro_entries").update({ position: i }).eq("id", id).eq("owner_id", user.id).eq("kind", kind),
    ),
  );
  const failed = results.find((r) => r.error);
  if (failed?.error) return { error: friendly(failed.error.message) };
  refresh(username);
  return { ok: true };
}
