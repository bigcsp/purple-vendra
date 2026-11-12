/**
 * Browser-side copy of the database's contact_problem() check, so people
 * see a warning while typing instead of after pressing Send. The database
 * is the real gatekeeper: it blocks these messages even if this check is
 * skipped. Keep the two in step.
 */
export type ContactProblem = "phone" | "email" | "link" | "social" | "payment";

const WORDS: [RegExp, string][] = [
  [/\b(zero|oh)\b/g, "0"],
  [/\bone\b/g, "1"],
  [/\btwo\b/g, "2"],
  [/\bthree\b/g, "3"],
  [/\bfour\b/g, "4"],
  [/\bfive\b/g, "5"],
  [/\bsix\b/g, "6"],
  [/\bseven\b/g, "7"],
  [/\beight\b/g, "8"],
  [/\bnine\b/g, "9"],
];

export function contactProblem(text: string): ContactProblem | null {
  if (!text.trim()) return null;
  const s = text.toLowerCase();
  let w = s;
  for (const [re, d] of WORDS) w = w.replace(re, d);

  if (
    /(234|0)[789][01][0-9]{8}/.test(w.replace(/[\s\-.()/_+]/g, "")) ||
    /[0-9]{10,}/.test(w.replace(/[\-.()/_]/g, "")) ||
    /[0-9]{3,5}([\s\-./]+[0-9]{3,5}){2,}/.test(w) ||
    /\+\s*[0-9]([\s\-.]?[0-9]){8,}/.test(w)
  )
    return "phone";

  if (
    /[a-z0-9._%+-]+\s*(@|\(at\)|\[at\])\s*[a-z0-9-]+(\.|\s*\(dot\)\s*|\s*\[dot\]\s*| dot )[a-z]{2,}/.test(s) ||
    /\b(gmail|yahoo|hotmail|outlook|icloud|proton\s*mail|ymail)\b/.test(s)
  )
    return "email";

  if (
    /(https?:\/\/|www\.)/.test(s) ||
    /\b[a-z0-9-]{2,}(\.|\s*\(dot\)\s*|\s*\[dot\]\s*| dot )(com|ng|net|org|io|me|co|link|bio|ly|app|site|store|shop|xyz|info)\b/.test(s)
  )
    return "link";

  if (
    /(whats\s*app|whatsap|watsapp|wats\s*app|wa\.me|\bw\/a\b|telegram|t\.me\/|\bsignal\s*app|instagram|\binsta\b|\big\b|snap\s*chat|facebook|\bfb\b|messenger|tik\s*tok|twitter|linked\s*in|viber|wechat)/.test(s) ||
    /(call\s*me|text\s*me|dm\s*me|ping\s*me|reach\s*me\s*(on|at|via)|my\s*(phone|number|line|contact|digits|handle|email|mail|socials?|page))/.test(s) ||
    /(^|\s)@[a-z0-9_.]{3,}/.test(s)
  )
    return "social";

  if (
    /(account\s*(no|num|number|details?)|acct\s*(no|num)|a\/c\s*(no|num)|bank\s*(transfer|details?|account)|\btransfer\s*(to|into|the\s*money|the\s*payment)|\bpay\s*(me\s*)?(directly|outside|offline|to\s*my|into\s*my|cash)|send\s*(the\s*)?(money|payment|cash)\s*(to|into)|\bcash\b|pay\s*on\s*delivery|payment\s*on\s*delivery|\bpod\b|\bopay\b|palm\s*pay|monie\s*point|\bkuda\b|chipper|paypal|western\s*union|\busdt\b|bitcoin|\bbtc\b|crypto|gift\s*card|\bpos\s*(transfer|payment))/.test(
      s,
    )
  )
    return "payment";

  return null;
}

export const CONTACT_MESSAGES: Record<ContactProblem, string> = {
  phone: "Phone and account numbers can't be shared on Purple Shop. Keep the chat here so you're protected.",
  email: "Email addresses can't be shared on Purple Shop. Keep the chat here so you're protected.",
  link: "Links to other websites can't be shared on Purple Shop.",
  social: "WhatsApp, Instagram and other contact handles can't be shared. Chat on Purple Shop instead.",
  payment: "Payments only go through Purple Shop escrow. Bank transfers, cash and payment apps aren't allowed.",
};
