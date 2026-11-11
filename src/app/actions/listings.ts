"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { nairaToKobo } from "@/lib/money";

export type ListingInput = {
  title: string;
  description: string;
  type: string;
  categoryId: number;
  price: string;
  priceIsStarting: boolean;
  deliveryMode: string;
  state: string;
  city: string;
  stock: string;
  submit: boolean; // true = send for review, false = keep as draft
};

const TYPES = ["product", "service", "talent"];
const MODES = ["delivery", "pickup", "digital", "in_person_service", "remote_service"];

function validate(input: ListingInput) {
  const title = input.title.trim();
  const description = input.description.trim();
  if (title.length < 3 || title.length > 120) return { error: "Title: 3–120 characters." };
  if (description.length < 10 || description.length > 5000) return { error: "Description: 10–5,000 characters." };
  if (!TYPES.includes(input.type)) return { error: "Choose what you're selling." };
  if (!MODES.includes(input.deliveryMode)) return { error: "Choose how buyers get it." };
  if (!Number.isInteger(input.categoryId)) return { error: "Choose a category." };
  const price = nairaToKobo(input.price);
  if (price === null || price < 10000) return { error: "Enter a price of at least ₦100." };
  const stock = input.stock.trim() === "" ? null : Number(input.stock);
  if (stock !== null && (!Number.isInteger(stock) || stock < 0)) return { error: "Stock must be a whole number." };
  return {
    row: {
      title,
      description,
      type: input.type,
      category_id: input.categoryId,
      price_kobo: price,
      price_is_starting: input.priceIsStarting,
      delivery_mode: input.deliveryMode,
      state: input.state.trim() || null,
      city: input.city.trim().slice(0, 80) || null,
      stock,
    },
  };
}

function friendly(message: string) {
  if (/2FA|row-level security/i.test(message))
    return "Not allowed. Make sure you're signed in with your 2FA code.";
  return message;
}

export async function createListing(input: ListingInput): Promise<{ id?: string; error?: string }> {
  const checked = validate(input);
  if ("error" in checked) return { error: checked.error };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Please sign in again." };

  const { data, error } = await supabase
    .from("listings")
    .insert({ ...checked.row, seller_id: user.id, status: input.submit ? "pending" : "draft" })
    .select("id")
    .single();
  if (error) return { error: friendly(error.message) };
  revalidatePath("/sell/listings");
  return { id: data.id };
}

export async function updateListing(id: string, input: ListingInput): Promise<{ id?: string; error?: string }> {
  const checked = validate(input);
  if ("error" in checked) return { error: checked.error };

  const supabase = await createClient();
  const { data: current } = await supabase.from("listings").select("status").eq("id", id).single();
  if (!current) return { error: "Listing not found." };

  // Approved listings stay live unless the seller edits what buyers rely on;
  // the database sends those edits back for review automatically.
  let status = current.status;
  if (current.status === "draft" || current.status === "rejected") status = input.submit ? "pending" : "draft";

  const { error } = await supabase.from("listings").update({ ...checked.row, status }).eq("id", id);
  if (error) return { error: friendly(error.message) };
  revalidatePath("/sell/listings");
  return { id };
}

export async function addListingPhotos(listingId: string, paths: string[]): Promise<{ error?: string }> {
  if (paths.length === 0) return {};
  const supabase = await createClient();
  const { data: existing } = await supabase
    .from("listing_images")
    .select("position")
    .eq("listing_id", listingId)
    .order("position", { ascending: false })
    .limit(1);
  const start = (existing?.[0]?.position ?? -1) + 1;
  const { error } = await supabase
    .from("listing_images")
    .insert(paths.map((storage_path, i) => ({ listing_id: listingId, storage_path, position: start + i })));
  if (error) return { error: friendly(error.message) };
  return {};
}

export async function removeListingPhoto(photoId: string): Promise<{ error?: string }> {
  const supabase = await createClient();
  const { data: photo } = await supabase.from("listing_images").select("storage_path").eq("id", photoId).single();
  if (!photo) return { error: "Photo not found." };
  const { error } = await supabase.from("listing_images").delete().eq("id", photoId);
  if (error) return { error: friendly(error.message) };
  await supabase.storage.from("listing-images").remove([photo.storage_path]);
  return {};
}

export async function deleteListing(id: string): Promise<{ error?: string }> {
  const supabase = await createClient();
  const { data: photos } = await supabase.from("listing_images").select("storage_path").eq("listing_id", id);
  const { error, count } = await supabase.from("listings").delete({ count: "exact" }).eq("id", id);
  if (error) return { error: friendly(error.message) };
  if (!count) return { error: "Listing not found." };
  if (photos?.length) await supabase.storage.from("listing-images").remove(photos.map((p) => p.storage_path));
  revalidatePath("/sell/listings");
  return {};
}
