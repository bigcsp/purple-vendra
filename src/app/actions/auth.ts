"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { safeNext } from "@/lib/safe-next";

export type FormState = { error?: string; message?: string };

const USERNAME = /^[a-z0-9_]{3,30}$/;

async function siteOrigin() {
  const h = await headers();
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  const proto = h.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  return `${proto}://${host}`;
}

export async function signUp(_prev: FormState, formData: FormData): Promise<FormState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const displayName = String(formData.get("display_name") ?? "").trim();
  const username = String(formData.get("username") ?? "").trim().toLowerCase();
  const intentRaw = String(formData.get("intent") ?? "");
  const intent = intentRaw === "sell" || intentRaw === "both" ? intentRaw : "shop";
  const next = safeNext(formData.get("next"), "");
  // Sellers go to the shop set-up checklist; shoppers back to what they were looking at.
  const after = intent === "shop" ? next || "/welcome" : "/welcome";

  if (!displayName || displayName.length > 80) return { error: "Enter your name (up to 80 characters)." };
  if (!USERNAME.test(username))
    return { error: "Username: 3–30 characters, lowercase letters, numbers or _ only." };
  if (password.length < 8) return { error: "Password must be at least 8 characters." };

  const supabase = await createClient();

  const { data: available } = await supabase.rpc("username_available", { wanted: username });
  if (available === false) return { error: `@${username} is already taken. Try another username.` };

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { username, display_name: displayName, intent },
      emailRedirectTo: `${await siteOrigin()}/auth/confirm?next=${encodeURIComponent(after)}`,
    },
  });
  if (error) return { error: error.message };

  // Email confirmation turned off in Supabase: the user is signed in already.
  if (data.session) redirect(after);

  return { message: `Almost done! We sent a link to ${email}. Open it to confirm your account.` };
}

export async function signIn(_prev: FormState, formData: FormData): Promise<FormState> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const next = safeNext(formData.get("next"));

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return {
      error:
        error.code === "email_not_confirmed"
          ? "Please confirm your email first. Check your inbox for our link."
          : "Wrong email or password.",
    };
  }

  // Has an authenticator app? Ask for the 6-digit code before going on.
  const has2fa = (data.user.factors ?? []).some((f) => f.status === "verified");
  if (has2fa) redirect(`/login/verify?next=${encodeURIComponent(next)}`);

  redirect(next);
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/");
}

export async function becomeSeller(): Promise<FormState> {
  const supabase = await createClient();
  // The database checks sign-in, 2FA and the 2FA-confirmed session itself.
  const { error } = await supabase.rpc("become_seller");
  if (error) return { error: error.message };
  // Back to the set-up checklist: profile, first listing, first story.
  redirect("/welcome");
}
