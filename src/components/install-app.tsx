"use client";

import { useEffect, useState, useSyncExternalStore } from "react";

/**
 * "Install the app" helpers.
 * - Android / Chrome / Edge: uses the browser's own install prompt.
 * - iPhone / iPad Safari: there's no prompt, so we show the 2-tap steps.
 * - Already installed (opened from the home screen): shows nothing.
 */
type PromptEvent = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: "accepted" | "dismissed" }> };

let deferred: PromptEvent | null = null;
const listeners = new Set<() => void>();
const notify = () => listeners.forEach((l) => l());

if (typeof window !== "undefined") {
  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    deferred = e as PromptEvent;
    notify();
  });
  window.addEventListener("appinstalled", () => {
    deferred = null;
    try {
      localStorage.setItem("ps-installed", "1");
    } catch {
      /* ignore */
    }
    notify();
  });
}

type Mode = "none" | "prompt" | "ios" | "installed";

function currentMode(): Mode {
  const standalone =
    window.matchMedia("(display-mode: standalone)").matches ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true;
  if (standalone) return "installed";
  if (deferred) return "prompt";
  const ua = navigator.userAgent;
  const ios = /iphone|ipad|ipod/i.test(ua) || (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1);
  if (ios && /safari/i.test(ua) && !/crios|fxios|edgios/i.test(ua)) return "ios";
  return "none";
}

function useInstallMode(): Mode {
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    currentMode,
    () => "none",
  );
}

async function promptInstall() {
  if (!deferred) return;
  await deferred.prompt();
  await deferred.userChoice.catch(() => null);
  deferred = null;
  notify();
}

/** Registers the offline helper once (production only). */
export function RegisterServiceWorker() {
  useEffect(() => {
    if (process.env.NODE_ENV !== "production" || !("serviceWorker" in navigator)) return;
    navigator.serviceWorker.register("/sw.js", { scope: "/" }).catch(() => {
      /* the site still works without it */
    });
  }, []);
  return null;
}

function IosSteps() {
  return (
    <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm">
      <li>
        Tap the <strong>Share</strong> button{" "}
        <svg viewBox="0 0 24 24" className="inline h-4 w-4 align-[-2px]" fill="none" stroke="currentColor" strokeWidth="2" aria-label="Share icon">
          <path d="M12 3v12M8 7l4-4 4 4M5 11v9h14v-9" strokeLinecap="round" strokeLinejoin="round" />
        </svg>{" "}
        at the bottom of Safari.
      </li>
      <li>
        Choose <strong>Add to Home Screen</strong>, then tap <strong>Add</strong>.
      </li>
    </ol>
  );
}

/** A card with the install button, for the account page. */
export function InstallAppCard() {
  const mode = useInstallMode();
  const [showIos, setShowIos] = useState(false);
  if (mode === "none" || mode === "installed") return null;

  return (
    <div className="flex items-start gap-4 rounded-3xl border border-border bg-card p-5">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/icons/icon-192.png" alt="" className="h-12 w-12 shrink-0 rounded-xl" />
      <div className="min-w-0 flex-1">
        <p className="font-semibold text-brand-strong">Get the Purple Shop app</p>
        <p className="text-sm text-muted">Opens from your home screen like any app. Free, no app store, uses little data.</p>
        {mode === "prompt" ? (
          <button type="button" onClick={promptInstall} className="mt-3 rounded-full bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-deep">
            Install app
          </button>
        ) : showIos ? (
          <IosSteps />
        ) : (
          <button type="button" onClick={() => setShowIos(true)} className="mt-3 rounded-full bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-deep">
            How to install
          </button>
        )}
      </div>
    </div>
  );
}

const DISMISS_KEY = "ps-install-dismissed";

function wasDismissed() {
  try {
    const t = Number(localStorage.getItem(DISMISS_KEY) ?? 0);
    return Date.now() - t < 30 * 86_400_000; // ask again after 30 days
  } catch {
    return true;
  }
}

/** Small dismissible bar above the phone menu. */
export function InstallAppBanner() {
  const mode = useInstallMode();
  const [hidden, setHidden] = useState(true);
  const [showIos, setShowIos] = useState(false);

  // Only after the page has loaded, and only if not dismissed recently.
  useEffect(() => {
    const t = window.setTimeout(() => setHidden(wasDismissed()), 2500);
    return () => window.clearTimeout(t);
  }, []);

  if (hidden || mode === "none" || mode === "installed") return null;

  const dismiss = () => {
    try {
      localStorage.setItem(DISMISS_KEY, String(Date.now()));
    } catch {
      /* ignore */
    }
    setHidden(true);
  };

  return (
    <div
      role="region"
      aria-label="Install the app"
      className="fixed inset-x-3 bottom-[calc(4.25rem+env(safe-area-inset-bottom))] z-40 rounded-2xl border border-border bg-card p-3 shadow-2xl md:bottom-4 md:left-auto md:right-4 md:w-96"
    >
      <div className="flex items-center gap-3">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/icons/icon-192.png" alt="" className="h-10 w-10 shrink-0 rounded-xl" />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-brand-strong">Add Purple Shop to your home screen</p>
          <p className="text-xs text-muted">Faster, full screen, no app store.</p>
        </div>
        {mode === "prompt" ? (
          <button type="button" onClick={promptInstall} className="shrink-0 rounded-full bg-brand px-3.5 py-1.5 text-sm font-medium text-white hover:bg-brand-deep">
            Install
          </button>
        ) : (
          <button type="button" onClick={() => setShowIos((v) => !v)} className="shrink-0 rounded-full bg-brand px-3.5 py-1.5 text-sm font-medium text-white hover:bg-brand-deep">
            How
          </button>
        )}
        <button type="button" onClick={dismiss} aria-label="Not now" className="shrink-0 rounded-full p-1.5 text-muted hover:bg-brand-soft hover:text-brand">
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden>
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </div>
      {mode === "ios" && showIos && <IosSteps />}
    </div>
  );
}
