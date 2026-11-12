import type { Metadata } from "next";
import Link from "next/link";
import { PageShell } from "@/components/page-shell";
import { Card } from "@/components/ui";

export const metadata: Metadata = { title: "Privacy policy · Purple Shop" };

/**
 * DRAFT privacy policy. Must be reviewed by a Nigerian data-protection
 * lawyer and given a real contact email before launch.
 */
export default function PrivacyPolicyPage() {
  return (
    <PageShell>
      <Card>
        <p className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
          Draft. This policy is being finalised and reviewed before Purple Shop fully launches.
        </p>
        <h1 className="mt-4 text-2xl font-bold text-brand-strong">Privacy policy</h1>
        <p className="mt-1 text-sm text-muted">Last updated 12 November 2026</p>

        <div className="mt-6 space-y-6 text-sm leading-relaxed">
          <Section title="Who we are">
            Purple Shop is an online marketplace for Nigerian creatives, freelancers and home-service professionals. We
            follow the Nigeria Data Protection Act 2023 (NDPA).
          </Section>

          <Section title="What we collect">
            <ul className="list-disc space-y-1 pl-5">
              <li><strong>Account:</strong> your name, username, email, password (stored scrambled) and two-factor settings.</li>
              <li><strong>Sellers:</strong> your shop details, listings, photos, Purple Stories videos, working hours and service areas.</li>
              <li><strong>Seller verification:</strong> a photo of your ID and your bank details, so we can pay you and keep buyers safe.</li>
              <li><strong>Orders and bookings:</strong> what you bought or booked, delivery or service address, and payment records.</li>
              <li><strong>Messages, reviews, comments and reports</strong> you send on Purple Shop.</li>
              <li><strong>Anonymous statistics:</strong> views, searches and clicks, counted without saying who did them.</li>
            </ul>
          </Section>

          <Section title="Why we use it">
            To run your account and the marketplace, take and hold payments safely until delivery, pay sellers, prevent fraud
            and abuse, show sellers anonymous demand insights, and meet our legal duties. We don&apos;t sell your data.
          </Section>

          <Section title="Who can see it">
            <ul className="list-disc space-y-1 pl-5">
              <li>Everyone can see sellers&apos; shop pages, listings and published stories.</li>
              <li>A seller sees a buyer&apos;s delivery or service address only for an order or booking they accepted.</li>
              <li>Only you and our review team can see your ID document.</li>
              <li>Alerts to sellers about saves and carts never say who you are.</li>
              <li>
                Your email address and phone number are never shown to other people. In chats, buyers see a seller&apos;s
                shop name and sellers see a buyer&apos;s username only.
              </li>
              <li>
                Only the two people in a chat can read it. Our team reads a chat only when it&apos;s reported or part of an
                order dispute.
              </li>
            </ul>
          </Section>

          <Section title="Escrow-only payments and contact details">
            All payments go through Purple Shop escrow, so we never need you to share bank details, phone numbers or
            emails with other people. To protect you, we automatically block messages, listings, stories, comments,
            reviews and profiles that contain contact details, links, social media handles or requests to pay another
            way. See <Link href="/safety" className="text-brand underline">How we keep you safe</Link>.
          </Section>

          <Section title="Where it's stored">
            Our database and files are hosted by Supabase in London, United Kingdom. The website itself is served by Vercel,
            which delivers pages from servers around the world. Both protect data in transit and at rest.
          </Section>

          <Section title="How long we keep it">
            <ul className="list-disc space-y-1 pl-5">
              <li>ID photos: deleted 180 days after approval, or 30 days after a rejected upload.</li>
              <li>Delivery and service addresses: deleted 90 days after the order or booking is finished.</li>
              <li>Messages: 2 years. Notifications: 6 months after you read them.</li>
              <li>Payment records: kept as long as the law requires, then deleted.</li>
            </ul>
          </Section>

          <Section title="Your rights">
            You can see and download your data (including your chats and the people you blocked), correct it, or delete your
            account at any time from{" "}
            <Link href="/account/privacy" className="text-brand underline">Your data & privacy</Link>. Deleting your
            account gives you 30 days to change your mind. You can also complain to the Nigeria Data Protection Commission
            (NDPC).
          </Section>

          <Section title="Security">
            Sellers must use two-factor authentication. Our database enforces who can see and change what, and we keep a
            tamper-proof log of sensitive actions.
          </Section>
        </div>
      </Card>
    </PageShell>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="text-base font-semibold text-brand-strong">{title}</h2>
      <div className="mt-1 text-foreground/90">{children}</div>
    </section>
  );
}
