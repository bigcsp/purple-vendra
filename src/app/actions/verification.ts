"use server";

import { redirect } from "next/navigation";
import { ID_TYPES } from "@/lib/id-types";
import { createClient } from "@/lib/supabase/server";

/** Saves (or replaces) the seller's verification after the file is uploaded. */
export async function submitVerification(idType: string, documentPath: string): Promise<{ error?: string }> {
  if (!(idType in ID_TYPES)) return { error: "Choose the type of ID you uploaded." };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login?next=/sell/verify");

  if (!documentPath.startsWith(`${user.id}/`)) return { error: "Upload your ID document first." };

  // The database forces status back to "pending" and checks the rest.
  const { error } = await supabase.from("seller_verifications").upsert(
    { user_id: user.id, id_type: idType, id_document_path: documentPath },
    { onConflict: "user_id" },
  );
  if (error) return { error: error.message };

  redirect("/sell/verify?submitted=1");
}
