import "server-only";

import { createServerClient } from "@supabase/ssr";
import { createClient as createPlainClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import { connection } from "next/server";
import { supabaseKey, supabaseUrl } from "./env";

/**
 * Supabase client that acts as the signed-in user (reads the session cookie).
 * Use inside Server Components, Server Actions and Route Handlers.
 * Reads the request, so components using it must sit behind <Suspense>.
 */
export async function createClient() {
  // Supabase checks the login session's expiry time (Date.now()) as soon as
  // the client is created. Next.js 16 doesn't allow that while pre-rendering,
  // so make every signed-in database call happen at request time.
  await connection();
  const cookieStore = await cookies();

  return createServerClient(supabaseUrl, supabaseKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        } catch {
          // Called from a Server Component: cookies can't be set here.
          // The proxy refreshes the session, so this is safe to ignore.
        }
      },
    },
  });
}

/**
 * Supabase client with NO user session, for public data
 * (categories, approved listings). Safe to use inside "use cache".
 */
export function createPublicClient() {
  return createPlainClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
