import Link from "next/link";

/** The safety rules, shown above every inbox and chat. */
export function EscrowNote({ compact = false }: { compact?: boolean }) {
  return (
    <div className="rounded-2xl border border-brand/25 bg-brand-soft/60 px-4 py-3 text-sm text-brand-strong">
      <p className="font-semibold">🔒 Pay only through Purple Shop escrow</p>
      {!compact && (
        <p className="mt-0.5 text-brand-strong/85">
          Your money is held safely until you confirm you got what you paid for. Phone numbers, emails, social handles,
          links and bank details can&apos;t be shared in chats, and nobody on Purple Shop will ever ask you to pay by
          transfer, cash or another app.{" "}
          <Link href="/safety" className="font-medium underline">How we keep you safe</Link>
        </p>
      )}
    </div>
  );
}
