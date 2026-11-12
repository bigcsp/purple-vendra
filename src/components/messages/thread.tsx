"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";
import { archiveConversation, markConversationRead, sendMessage, setBlocked } from "@/app/actions/messages";
import { ReportButton } from "@/components/report-button";
import { CONTACT_MESSAGES, contactProblem } from "@/lib/contact-guard";

type Msg = { id: string; sender_id: string; body: string; created_at: string; read_at: string | null };

const REFRESH_MS = 6000;

export function Thread({
  conversationId,
  myId,
  otherId,
  otherLabel,
  youAre,
  listingId,
  initialMessages,
  youBlocked,
  closed,
  closedReason,
}: {
  conversationId: string;
  myId: string;
  otherId: string;
  otherLabel: string;
  youAre: "buyer" | "seller";
  listingId: string | null;
  initialMessages: Msg[];
  youBlocked: boolean;
  closed: boolean;
  closedReason: string | null;
}) {
  const router = useRouter();
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();
  const [menuPending, startMenu] = useTransition();
  // Messages sent from this page show at once, before the server refresh catches up.
  const [sentHere, setSentHere] = useState<Msg[]>([]);
  const bottom = useRef<HTMLDivElement>(null);

  const serverIds = new Set(initialMessages.map((m) => m.id));
  const messages = [...initialMessages, ...sentHere.filter((m) => !serverIds.has(m.id))];
  const lastId = messages.at(-1)?.id;
  const unreadFromOther = initialMessages.some((m) => m.sender_id !== myId && !m.read_at);

  const problem = contactProblem(draft);

  // Keep the chat fresh while it's open on screen.
  useEffect(() => {
    const tick = () => {
      if (document.visibilityState === "visible") router.refresh();
    };
    const timer = window.setInterval(tick, REFRESH_MS);
    document.addEventListener("visibilitychange", tick);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", tick);
    };
  }, [router]);

  // Mark the other person's messages as read.
  useEffect(() => {
    if (unreadFromOther) void markConversationRead(conversationId);
  }, [conversationId, unreadFromOther, lastId]);

  useEffect(() => {
    bottom.current?.scrollIntoView({ block: "end" });
  }, [lastId]);

  function send(e?: React.FormEvent) {
    e?.preventDefault();
    const text = draft.trim();
    if (!text || pending) return;
    if (problem) return setError(CONTACT_MESSAGES[problem]);
    start(async () => {
      setError(null);
      const r = await sendMessage(conversationId, text);
      if (r.error || !r.id) return setError(r.error ?? "Couldn't send. Please try again.");
      setSentHere((s) => [...s, { id: r.id!, sender_id: myId, body: text, created_at: new Date().toISOString(), read_at: null }]);
      setDraft("");
      router.refresh();
    });
  }

  return (
    <div className="space-y-3">
      <div className="max-h-[60vh] min-h-64 space-y-2 overflow-y-auto rounded-3xl border border-border bg-card p-4" aria-live="polite">
        {messages.length === 0 && (
          <div className="py-10 text-center text-sm text-muted">
            <p className="font-medium text-brand-strong">Start the conversation</p>
            <p className="mt-1">
              {youAre === "buyer"
                ? "Ask about sizes, colours, delivery time or a custom order."
                : "Say hello and answer their questions."}
            </p>
          </div>
        )}
        {messages.map((m, i) => {
          const mine = m.sender_id === myId;
          const day = dayLabel(m.created_at);
          const showDay = i === 0 || dayLabel(messages[i - 1].created_at) !== day;
          return (
            <div key={m.id}>
              {showDay && <p className="my-3 text-center text-xs text-muted">{day}</p>}
              <div className={`flex ${mine ? "justify-end" : "justify-start"}`}>
                <div
                  className={`max-w-[80%] rounded-2xl px-3.5 py-2 text-sm ${
                    mine ? "rounded-br-md bg-brand text-white" : "rounded-bl-md bg-brand-soft text-foreground"
                  }`}
                >
                  <p className="whitespace-pre-wrap break-words">{m.body}</p>
                  <p className={`mt-0.5 text-right text-[11px] ${mine ? "text-white/75" : "text-muted"}`}>
                    {time(m.created_at)}
                    {mine && (m.read_at ? " · Seen" : "")}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
        <div ref={bottom} />
      </div>

      {closed ? (
        <p className="rounded-2xl border border-border bg-card p-4 text-center text-sm text-muted">{closedReason}</p>
      ) : (
        <form onSubmit={send} className="space-y-2">
          <label htmlFor="message" className="sr-only">Message {otherLabel}</label>
          <div className="flex items-end gap-2">
            <textarea
              id="message"
              value={draft}
              onChange={(e) => {
                setDraft(e.target.value);
                setError(null);
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
                  e.preventDefault();
                  send();
                }
              }}
              rows={2}
              maxLength={2000}
              placeholder={`Message ${otherLabel}…`}
              aria-invalid={problem ? true : undefined}
              aria-describedby="message-help"
              className={`block min-h-12 w-full resize-y rounded-2xl border bg-card px-3.5 py-2.5 text-sm outline-none focus:ring-2 ${
                problem ? "border-red-400 focus:ring-red-100" : "border-border focus:border-brand focus:ring-brand-soft"
              }`}
            />
            <button
              type="submit"
              disabled={pending || !draft.trim() || !!problem}
              className="shrink-0 rounded-2xl bg-brand px-5 py-3 text-sm font-medium text-white hover:bg-brand-deep disabled:opacity-50"
            >
              {pending ? "Sending…" : "Send"}
            </button>
          </div>
          <p id="message-help" className={`text-xs ${problem || error ? "text-red-700" : "text-muted"}`} role={problem || error ? "alert" : undefined}>
            {problem ? CONTACT_MESSAGES[problem] : error ?? "Enter to send · Shift+Enter for a new line"}
          </p>
        </form>
      )}

      <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
        {youAre === "buyer" && listingId && (
          <Link href={`/l/${listingId}`} className="font-medium text-brand hover:underline">
            Buy safely on Purple Shop →
          </Link>
        )}
        <button
          type="button"
          disabled={menuPending}
          onClick={() =>
            startMenu(async () => {
              await archiveConversation(conversationId, true);
              router.push("/messages");
            })
          }
          className="text-muted underline hover:text-brand"
        >
          Archive chat
        </button>
        <button
          type="button"
          disabled={menuPending}
          onClick={() =>
            startMenu(async () => {
              if (!youBlocked && !window.confirm(`Block ${otherLabel}? They won't be able to message you.`)) return;
              const r = await setBlocked(otherId, !youBlocked, conversationId);
              if (r.error) setError(r.error);
              router.refresh();
            })
          }
          className="text-muted underline hover:text-brand"
        >
          {youBlocked ? "Unblock" : "Block"}
        </button>
      </div>
      <ReportButton userId={otherId} label={`Report ${otherLabel}`} />
    </div>
  );
}

function time(iso: string) {
  return new Date(iso).toLocaleTimeString("en-NG", { hour: "numeric", minute: "2-digit", timeZone: "Africa/Lagos" });
}

function dayLabel(iso: string) {
  const d = new Date(iso);
  const today = new Date();
  const yesterday = new Date(today.getTime() - 86_400_000);
  const fmt = (x: Date) => x.toLocaleDateString("en-NG", { timeZone: "Africa/Lagos" });
  if (fmt(d) === fmt(today)) return "Today";
  if (fmt(d) === fmt(yesterday)) return "Yesterday";
  return d.toLocaleDateString("en-NG", { weekday: "short", day: "numeric", month: "short", timeZone: "Africa/Lagos" });
}
