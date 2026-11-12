"use client";

import { useSyncExternalStore } from "react";
import { setSaved } from "@/server/actions/saves";

/**
 * One shared copy of "which listings have I saved" for the whole page,
 * so every heart agrees. Loaded once from /api/saves.
 */
type State = { loaded: boolean; signedIn: boolean; ids: Set<string> };

let state: State = { loaded: false, signedIn: false, ids: new Set() };
let loading: Promise<void> | null = null;
const listeners = new Set<() => void>();
const SERVER_STATE: State = { loaded: false, signedIn: false, ids: new Set() };

function emit(next: State) {
  state = next;
  listeners.forEach((l) => l());
}

function load() {
  if (loading) return loading;
  loading = fetch("/api/saves")
    .then((r) => r.json())
    .then((j: { signedIn: boolean; ids: string[] }) => emit({ loaded: true, signedIn: j.signedIn, ids: new Set(j.ids) }))
    .catch(() => emit({ ...state, loaded: true }));
  return loading;
}

function subscribe(cb: () => void) {
  listeners.add(cb);
  void load();
  return () => listeners.delete(cb);
}

export function useSaved() {
  return useSyncExternalStore(subscribe, () => state, () => SERVER_STATE);
}

/** Flip a save. Returns "signin" when the person needs an account first. */
export async function toggleSaved(listingId: string): Promise<"ok" | "signin" | string> {
  await load();
  const was = state.ids.has(listingId);
  const optimistic = new Set(state.ids);
  if (was) optimistic.delete(listingId);
  else optimistic.add(listingId);
  if (state.signedIn) emit({ ...state, ids: optimistic });

  const r = await setSaved(listingId, !was);
  if (r.signIn) {
    emit({ ...state, signedIn: false, ids: new Set() });
    return "signin";
  }
  if (r.error) {
    const back = new Set(state.ids);
    if (was) back.add(listingId);
    else back.delete(listingId);
    emit({ ...state, ids: back });
    return r.error;
  }
  if (!state.signedIn) emit({ loaded: true, signedIn: true, ids: optimistic });
  return "ok";
}
