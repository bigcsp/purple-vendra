"use server";

import { revalidatePath } from "next/cache";
import { nairaToKobo } from "@/lib/money";
import { createClient } from "@/lib/supabase/server";

type Result = { ok?: true; error?: string; signIn?: true; id?: string };

const UUID = /^[0-9a-f-]{36}$/i;

function friendly(message: string) {
  if (/permission denied|row-level/i.test(message)) return "That isn't allowed.";
  return message;
}

async function signedIn() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return { supabase, user };
}

export type RequestInput = {
  title: string;
  description: string;
  categoryId: number;
  budget: string;
  state: string;
  city: string;
  deadline: string;
};

function args(input: RequestInput) {
  return {
    p_title: input.title,
    p_description: input.description,
    p_category: Number(input.categoryId) || null,
    p_budget_kobo: input.budget.trim() ? nairaToKobo(input.budget) : null,
    p_state: input.state,
    p_city: input.city,
    p_deadline: /^\d{4}-\d{2}-\d{2}$/.test(input.deadline) ? input.deadline : null,
  };
}

export async function createRequest(input: RequestInput): Promise<Result> {
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true };
  if (input.budget.trim() && nairaToKobo(input.budget) === null) return { error: "Enter the budget as a number, e.g. 150000." };
  const { data, error } = await supabase.rpc("create_request", args(input));
  if (error) return { error: friendly(error.message) };
  revalidatePath("/requests");
  return { ok: true, id: data as string };
}

export async function updateRequest(id: string, input: RequestInput): Promise<Result> {
  if (!UUID.test(id)) return { error: "Request not found." };
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true };
  const { error } = await supabase.rpc("update_request", { p_request: id, ...args(input) });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${id}`);
  revalidatePath("/requests");
  return { ok: true, id };
}

export async function closeRequest(id: string): Promise<Result> {
  if (!UUID.test(id)) return { error: "Request not found." };
  const { supabase } = await signedIn();
  const { error } = await supabase.rpc("close_request", { p_request: id });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${id}`);
  revalidatePath("/requests");
  return { ok: true };
}

export async function sendOffer(input: {
  requestId: string;
  price: string;
  days: string;
  message: string;
  listingId: string;
}): Promise<Result> {
  if (!UUID.test(input.requestId)) return { error: "Request not found." };
  const { supabase, user } = await signedIn();
  if (!user) return { signIn: true };
  const price = nairaToKobo(input.price);
  if (price === null) return { error: "Enter your price as a number, e.g. 120000." };
  const days = Number.parseInt(input.days, 10);
  const { data, error } = await supabase.rpc("send_offer", {
    p_request: input.requestId,
    p_price_kobo: price,
    p_delivery_days: Number.isFinite(days) ? days : null,
    p_message: input.message,
    p_listing: UUID.test(input.listingId) ? input.listingId : null,
  });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${input.requestId}`);
  return { ok: true, id: data as string };
}

export async function withdrawOffer(offerId: string, requestId: string): Promise<Result> {
  if (!UUID.test(offerId)) return { error: "Offer not found." };
  const { supabase } = await signedIn();
  const { error } = await supabase.rpc("withdraw_offer", { p_offer: offerId });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${requestId}`);
  return { ok: true };
}

export async function declineOffer(offerId: string, requestId: string): Promise<Result> {
  if (!UUID.test(offerId)) return { error: "Offer not found." };
  const { supabase } = await signedIn();
  const { error } = await supabase.rpc("decline_offer", { p_offer: offerId });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${requestId}`);
  return { ok: true };
}

/** Accepting closes the request and opens a private chat with that seller. */
export async function acceptOffer(offerId: string, requestId: string): Promise<Result> {
  if (!UUID.test(offerId)) return { error: "Offer not found." };
  const { supabase } = await signedIn();
  const { data, error } = await supabase.rpc("accept_offer", { p_offer: offerId });
  if (error) return { error: friendly(error.message) };
  revalidatePath(`/requests/${requestId}`);
  revalidatePath("/requests");
  revalidatePath("/messages");
  return { ok: true, id: data as string };
}
