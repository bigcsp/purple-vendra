import type { Metadata } from "next";
import Link from "next/link";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";

export const metadata: Metadata = { title: "How we keep you safe · Purple Shop" };

export default function SafetyPage() {
  return (
    <PageShell>
      <Card>
        <h1 className="text-2xl font-bold text-brand-strong">How we keep you safe</h1>
        <p className="mt-2 text-muted">
          Purple Shop holds your payment in escrow and keeps everyone&apos;s contact details private. These rules protect
          buyers and sellers alike.
        </p>

        <div className="mt-6 space-y-6 text-sm leading-relaxed">
          <Rule title="Every payment goes through Purple Shop escrow">
            When you pay, Purple Shop holds the money. The seller is paid only after you confirm you received what you
            ordered, or after the delivery window passes without a problem being reported. If something goes wrong, you
            can open a dispute and our team decides with both sides&apos; evidence.
          </Rule>

          <Rule title="Never pay outside Purple Shop">
            Bank transfers, cash, pay-on-delivery, POS, payment apps, crypto and gift cards aren&apos;t allowed, and they
            aren&apos;t protected. If anyone asks you to pay another way, don&apos;t. Report them from the chat or their
            shop page.
          </Rule>

          <Rule title="Contact details stay private">
            Your email address and phone number are never shown to other people. Chats, listings, stories, comments,
            reviews and shop profiles can&apos;t contain phone numbers, emails, links, social media handles or bank
            details. Purple Shop blocks them automatically, including numbers written out in words.
          </Rule>

          <Rule title="Private chats">
            Only you and the person you&apos;re talking to can read a chat. Our team reads a chat only when one of you
            reports it or opens a dispute about an order. You can archive a chat, block someone so they can&apos;t message
            you, or report them at any time.
          </Rule>

          <Rule title="Verified sellers">
            Sellers sign in with two-factor authentication. Sellers with a ✓ have had their ID checked by our team. Home
            services can only be offered by ID-verified sellers.
          </Rule>

          <Rule title="Spot a scam">
            <ul className="list-disc space-y-1 pl-5">
              <li>A price that looks far too low.</li>
              <li>Pressure to decide fast or to &quot;move to WhatsApp&quot;.</li>
              <li>A request to pay a deposit by transfer &quot;to hold the item&quot;.</li>
              <li>Anyone claiming to be Purple Shop staff in a chat. We never ask for your password or codes.</li>
            </ul>
          </Rule>
        </div>

        <p className="mt-8 text-sm text-muted">
          More about how we handle your data: <Link href="/privacy" className="text-brand underline">Privacy policy</Link>.
        </p>
      </Card>
    </PageShell>
  );
}

function Rule({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="text-base font-semibold text-brand-strong">{title}</h2>
      <div className="mt-1 text-foreground/90">{children}</div>
    </section>
  );
}
