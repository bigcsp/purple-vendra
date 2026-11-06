"use client";

import { createBrowserClient } from "@supabase/ssr";
import { supabaseKey, supabaseUrl } from "./env";

/** Supabase client for Client Components (runs in the browser). */
export function createClient() {
  return createBrowserClient(supabaseUrl, supabaseKey);
}
