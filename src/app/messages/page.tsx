import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { EscrowNote } from "@/components/messages/escrow-note";
import { PageShell } from "@/components/page-shell";
import { getCurrentUser } from "@/lib/auth";
import { getInbox } from "@/lib/messages";

export const metadata: Metadata = { title: "Messages · Purple Shop" };

export default function MessagesPage({ searchParams }: PageProps<"/messages">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading your messages…</p>}>
        <Inbox searchParams={searchParams} />
      </Suspense>
    </PageShell>
  );
}

async function Inbox({ searchParams }: { searchParams: PageProps<"/messages">["searchParams"] }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/messages");
  const { view } = await searchParams;
  const archived = view === "archived";
  const rows = await getInbox(archived);
  const isSeller = user.role !== "buyer";

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-brand-strong">Messages</h1>
          <p className="text-sm text-muted">Private chats between you and {isSeller ? "buyers and sellers" : "sellers"}.</p>
        </div>
        <div className="flex rounded-full border border-border bg-card p-1 text-sm">
          <Link href="/messages" aria-current={!archived ? "page" : undefined}
            className={`rounded-full px-3 py-1 font-medium ${!archived ? "bg-brand text-white" : "text-brand"}`}>
            Inbox
          </Link>
          <Link href="/messages?view=archived" aria-current={archived ? "page" : undefined}
            className={`rounded-full px-3 py-1 font-medium ${archived ? "bg-brand text-white" : "text-brand"}`}>
            Archived
          </Link>
        </div>
      </div>

      <EscrowNote />

      {rows.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-border bg-card p-8 text-center">
          <p className="font-medium text-brand-strong">{archived ? "No archived chats." : "No messages yet."}</p>
          {!archived && (
            <p className="mt-1 text-sm text-muted">
              Found something you like? Press <strong>Message seller</strong> on any listing or shop to ask a question.
            </p>
          )}
          {!archived && (
            <Link href="/search" className="mt-4 inline-block rounded-full bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-deep">
              Browse Purple Shop
            </Link>
          )}
        </div>
      ) : (
        <ul className="divide-y divide-border overflow-hidden rounded-3xl border border-border bg-card">
          {rows.map((c) => (
            <li key={c.id}>
              <Link href={`/messages/${c.id}`} className="flex items-center gap-3 px-4 py-3.5 hover:bg-brand-soft/50">
                <Avatar name={c.other_name} url={c.other_avatar} />
                <span className="min-w-0 flex-1">
                  <span className="flex items-baseline justify-between gap-2">
                    <span className={`truncate ${c.unread ? "font-bold text-brand-strong" : "font-medium"}`}>
                      {c.other_name}
                      <span className="ml-1.5 text-xs font-normal text-muted">{c.you_are === "seller" ? "Buyer" : "Seller"}</span>
                    </span>
                    <time className="shrink-0 text-xs text-muted" dateTime={c.last_message_at}>{when(c.last_message_at)}</time>
                  </span>
                  {c.listing_title && <span className="block truncate text-xs text-brand">About: {c.listing_title}</span>}
                  <span className={`block truncate text-sm ${c.unread ? "text-foreground" : "text-muted"}`}>
                    {c.blocked ? "Chat closed" : c.last_message ? `${c.last_from_you ? "You: " : ""}${c.last_message}` : "Say hello 👋"}
                  </span>
                </span>
                {c.unread > 0 && (
                  <span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-brand px-1.5 text-xs font-bold text-white">
                    {c.unread > 99 ? "99+" : c.unread}
                    <span className="sr-only"> unread</span>
                  </span>
                )}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function Avatar({ name, url }: { name: string; url: string | null }) {
  // eslint-disable-next-line @next/next/no-img-element
  if (url) return <img src={url} alt="" className="h-11 w-11 shrink-0 rounded-full object-cover" />;
  return (
    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-soft font-bold text-brand">
      {name.slice(0, 1).toUpperCase()}
    </span>
  );
}

function when(iso: string) {
  const d = new Date(iso);
  const now = new Date();
  if (d.toDateString() === now.toDateString())
    return d.toLocaleTimeString("en-NG", { hour: "numeric", minute: "2-digit", timeZone: "Africa/Lagos" });
  return d.toLocaleDateString("en-NG", { day: "numeric", month: "short", timeZone: "Africa/Lagos" });
}
