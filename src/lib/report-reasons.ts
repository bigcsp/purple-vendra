/** Reasons a user can give when reporting a listing or a person (matches the database check). */
export const REPORT_REASONS = {
  scam: "Scam or fraud",
  off_platform_payment: "Asked me to pay outside Purple Shop",
  counterfeit: "Fake or counterfeit item",
  misleading: "Photos or description are misleading",
  prohibited_item: "Item isn't allowed on Purple Shop",
  harassment: "Rude, threatening or abusive",
  fake_profile: "Fake profile or pretending to be someone",
  other: "Something else",
} as const;

export type ReportReason = keyof typeof REPORT_REASONS;
