import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Suspense } from "react";
import { EscrowNote } from "@/components/messages/escrow-note";
import { Thread } from "@/components/messages/thread";
import { PageShell } from "@/components/page-shell";
import { getCurrentUser } from "@/lib/auth";
import { getConversation } from "@/lib/messages";
import { formatNaira } from "@/lib/money";

export const metadata: Metadata = { title: "Chat · Purple Shop" };

export default function ChatPage({ params }: PageProps<"/messages/[id]">) {
  return (
    <PageShell>
      <Suspense fallback={<p className="text-sm text-muted">Loading chat…</p>}>
        <Chat params={params} />
      </Suspense>
    </PageShell>
  );
}

async function Chat({ params }: { params: PageProps<"/messages/[id]">["params"] }) {
  const { id } = await params;
  const user = await getCurrentUser();
  if (!user) redirect(`/login?next=/messages/${encodeURIComponent(id)}`);
  if (!/^[0-9a-f-]{36}$/i.test(id)) notFound();
  const chat = await getConversation(id);
  if (!chat) notFound();
  const { header: h, messages } = chat;

  return (
    <div className="space-y-4">
      <Link href="/messages" className="text-sm text-muted hover:text-brand">← All messages</Link>

      <div className="flex flex-wrap items-center gap-3 rounded-3xl border border-border bg-card p-4">
        {h.other_avatar ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={h.other_avatar} alt="" className="h-12 w-12 rounded-full object-cover" />
        ) : (
          <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brand-soft text-lg font-bold text-brand">
            {h.other_name.slice(0, 1).toUpperCase()}
          </span>
        )}
        <div className="min-w-0 flex-1">
          <p className="truncate font-semibold text-brand-strong">
            {h.other_is_seller ? (
              <Link href={`/shop/${h.other_username}`} className="hover:underline">{h.other_name}</Link>
            ) : (
              <>@{h.other_username}</>
            )}
          </p>
          <p className="text-xs text-muted">{h.you_are === "buyer" ? "Seller" : "Buyer"} · Only you two can see this chat</p>
        </div>
        {h.listing_id && h.listing_title && (
          <Link href={`/l/${h.listing_id}`} className="w-full rounded-2xl bg-brand-soft/60 px-3 py-2 text-sm sm:w-auto">
            <span className="block text-xs text-muted">About</span>
            <span className="font-medium text-brand-strong">{h.listing_title}</span>
            {h.listing_price_kobo != null && <span className="ml-2 text-muted">{formatNaira(h.listing_price_kobo)}</span>}
          </Link>
        )}
      </div>

      <EscrowNote compact />

      <Thread
        conversationId={h.id}
        myId={user.id}
        otherId={h.other_id}
        otherLabel={h.other_is_seller ? h.other_name : `@${h.other_username}`}
        youAre={h.you_are}
        listingId={h.listing_id}
        initialMessages={messages}
        youBlocked={h.you_blocked}
        closed={h.blocked || !h.other_available}
        closedReason={
          h.you_blocked
            ? "You blocked this person. Unblock them to chat again."
            : h.blocked
              ? "This chat is closed."
              : !h.other_available
                ? "This person isn't on Purple Shop any more."
                : null
        }
      />
    </div>
  );
}
