import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

/**
 * Runs before every page request:
 *  1. Keeps the Supabase login session fresh.
 *  2. Protects pages:
 *     /account/*  → must be signed in (and enter their 2FA code if they have 2FA)
 *     /sell/*     → must be signed in WITH a 2FA-confirmed session
 * The database enforces the same seller 2FA rule, so this is the
 * friendly front door, not the only lock.
 */
export async function proxy(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return NextResponse.next({ request });

  let response = NextResponse.next({ request });

  const supabase = createServerClient(url, key, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  // Refreshes the session token if it has expired and checks its signature.
  // Do not remove. getClaims() verifies the token on this server when the
  // project uses Supabase signing keys, so most visits skip a network call.
  const { data: claimsData } = await supabase.auth.getClaims();
  const user = claimsData?.claims?.sub ? { id: claimsData.claims.sub } : null;

  const path = request.nextUrl.pathname;
  const isAccount = path === "/account" || path.startsWith("/account/");
  const isSell = path === "/sell" || path.startsWith("/sell/");
  if (!isAccount && !isSell) return response;

  // Sends the visitor elsewhere while keeping any refreshed login cookies.
  const goTo = (pathname: string) => {
    const target = new URL(pathname, request.url);
    const redirect = NextResponse.redirect(target);
    response.cookies.getAll().forEach((c) => redirect.cookies.set(c));
    return redirect;
  };
  const next = encodeURIComponent(path + request.nextUrl.search);

  if (!user) return goTo(`/login?next=${next}`);

  const { data: aal } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
  const confirmed = aal?.currentLevel === "aal2";

  // Has 2FA but hasn't typed the code in this session yet.
  if (aal?.nextLevel === "aal2" && !confirmed) return goTo(`/login/verify?next=${next}`);

  // Seller pages need 2FA. No 2FA yet → set it up first.
  if (isSell && !confirmed) return goTo(`/account/security?next=${next}`);

  return response;
}

export const config = {
  matcher: [
    // Everything except static files and images
    "/((?!_next/static|_next/image|favicon.ico|ffmpeg/|icons/|sw\\.js|offline\\.html|manifest\\.webmanifest|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
