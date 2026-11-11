/** Money is stored in kobo (₦1 = 100 kobo) as whole numbers. */
export function formatNaira(kobo: number | string | null | undefined): string {
  const n = Number(kobo ?? 0) / 100;
  return `₦${n.toLocaleString("en-NG", { maximumFractionDigits: n % 1 === 0 ? 0 : 2 })}`;
}

/** "15,000" or "15000.50" → kobo, or null if it isn't a valid amount. */
export function nairaToKobo(input: FormDataEntryValue | string | null): number | null {
  const cleaned = String(input ?? "").replace(/[₦,\s]/g, "");
  if (!/^\d+(\.\d{1,2})?$/.test(cleaned)) return null;
  return Math.round(Number(cleaned) * 100);
}
