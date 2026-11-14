/** Purple Pro: shared labels and limits (safe in the browser). The database enforces the same limits. */

export type ProMode = "professional" | "creative_space";
export type ProEntryKind = "experience" | "education" | "certification" | "achievement";

export const PRO_MODES: Record<ProMode, { title: string; tagline: string; bestFor: string }> = {
  professional: {
    title: "Professional Profile",
    tagline: "A polished career profile: experience, skills, credentials and services.",
    bestFor: "Designers, developers, writers, consultants, tutors, marketers",
  },
  creative_space: {
    title: "My Creative Space",
    tagline: "A visual page built around your work: photos, videos, services and bookings.",
    bestFor: "Fashion designers, makeup artists, photographers, artisans, home-service pros",
  },
};

export const ENTRY_KINDS: Record<
  ProEntryKind,
  { title: string; singular: string; titleLabel: string; orgLabel: string; empty: string; dated: boolean }
> = {
  experience: {
    title: "Experience",
    singular: "experience",
    titleLabel: "Role or job title",
    orgLabel: "Company or client",
    empty: "Add the roles and engagements that show what you can do.",
    dated: true,
  },
  education: {
    title: "Education",
    singular: "education",
    titleLabel: "Qualification or course",
    orgLabel: "School or institution",
    empty: "Degrees, diplomas, apprenticeships and courses.",
    dated: true,
  },
  certification: {
    title: "Certifications",
    singular: "certification",
    titleLabel: "Certificate or licence",
    orgLabel: "Issued by",
    empty: "Professional certificates and trade licences.",
    dated: true,
  },
  achievement: {
    title: "Achievements",
    singular: "achievement",
    titleLabel: "Achievement or award",
    orgLabel: "Awarded by (optional)",
    empty: "Awards, notable projects, press features and milestones.",
    dated: false,
  },
};

export const ENTRY_KIND_ORDER: ProEntryKind[] = ["experience", "education", "certification", "achievement"];

export const PRO_LIMITS = {
  skills: 20,
  skillLength: 40,
  languages: 10,
  languageLength: 30,
  entriesPerSection: 25,
} as const;

export type ProEntry = {
  id: string;
  kind: ProEntryKind;
  title: string;
  organisation: string | null;
  location: string | null;
  start_year: number | null;
  end_year: number | null;
  is_current: boolean;
  description: string | null;
  position: number;
};

export const PRO_ENTRY_SELECT = "id, kind, title, organisation, location, start_year, end_year, is_current, description, position";

/** "2019 – Present", "2016 – 2020", "2021", or "" */
export function yearRange(e: Pick<ProEntry, "start_year" | "end_year" | "is_current">): string {
  if (e.start_year && e.is_current) return `${e.start_year} – Present`;
  if (e.start_year && e.end_year && e.end_year !== e.start_year) return `${e.start_year} – ${e.end_year}`;
  return String(e.start_year ?? e.end_year ?? "");
}

/** Public link for a professional page (relative). */
export const proPath = (username: string) => `/pro/${username}`;

export type StrengthInput = {
  hasPhoto: boolean;
  hasCover: boolean;
  headline: string | null;
  bio: string | null;
  hasLocation: boolean;
  skills: number;
  entries: Partial<Record<ProEntryKind, number>>;
  services: number;
  hasHours: boolean;
};

/** Profile strength checklist: what a strong page has, in order of impact. */
export function profileStrength(i: StrengthInput) {
  const items = [
    { label: "Profile photo or logo", done: i.hasPhoto, weight: 15, href: "/sell/profile" },
    { label: "Professional headline", done: !!i.headline?.trim(), weight: 15, href: "/sell/profile" },
    { label: "About you (at least 100 characters)", done: (i.bio?.trim().length ?? 0) >= 100, weight: 15, href: "/sell/profile" },
    { label: "At least 3 skills", done: i.skills >= 3, weight: 15, href: "#skills" },
    { label: "Experience, education or a certification", done: (i.entries.experience ?? 0) + (i.entries.education ?? 0) + (i.entries.certification ?? 0) > 0, weight: 15, href: "#experience" },
    { label: "A live service listing", done: i.services > 0, weight: 10, href: "/sell/listings/new" },
    { label: "Cover image", done: i.hasCover, weight: 5, href: "#cover" },
    { label: "Location", done: i.hasLocation, weight: 5, href: "/sell/profile" },
    { label: "Working hours", done: i.hasHours, weight: 5, href: "/sell/profile" },
  ];
  const score = items.reduce((s, x) => s + (x.done ? x.weight : 0), 0);
  return { score, items };
}
