"use client";

import { Check, Copy, Eye, EyeOff, ImagePlus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useSyncExternalStore, useTransition } from "react";
import { Notice } from "@/components/ui";
import { PRO_LIMITS } from "@/lib/pro";
import { uploadProfileCover } from "@/lib/upload";
import { saveSkillsAndLanguages, setCover, setProVisibility } from "@/server/actions/pro";
import { TagInput } from "./tag-input";

const noop = () => () => {};

type Msg = { tone: "error" | "success"; text: string } | undefined;

/** Public/private switch and the shareable link. */
export function VisibilityCard({ username, isPublic }: { username: string; isPublic: boolean }) {
  const router = useRouter();
  const [msg, setMsg] = useState<Msg>();
  const [copied, setCopied] = useState(false);
  const [pending, start] = useTransition();
  const path = `/pro/${username}`;
  const host = useSyncExternalStore(noop, () => window.location.host, () => "");

  async function copy() {
    const url = `${window.location.origin}${path}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      setMsg({ tone: "error", text: `Couldn't copy. Your link is ${url}` });
    }
  }

  return (
    <section className="rounded-3xl border border-border bg-card p-6 sm:p-8">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <h2 className="text-lg font-semibold text-brand-strong">Visibility</h2>
            <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
              isPublic ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-700"
            }`}>
              {isPublic ? <Eye className="h-3 w-3" aria-hidden /> : <EyeOff className="h-3 w-3" aria-hidden />}
              {isPublic ? "Public" : "Private"}
            </span>
          </div>
          <p className="mt-1 text-sm text-muted">
            {isPublic
              ? "Anyone with your link can view your page, and customers can find you on Purple Shop."
              : "Only you can see your page. Make it public when you're ready to be found."}
          </p>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={isPublic}
          aria-label="Public page"
          disabled={pending}
          onClick={() =>
            start(async () => {
              setMsg(undefined);
              const r = await setProVisibility(!isPublic);
              if (r.error) return setMsg({ tone: "error", text: r.error });
              router.refresh();
            })
          }
          className={`relative h-7 w-12 shrink-0 rounded-full transition disabled:opacity-60 ${isPublic ? "bg-brand" : "bg-border"}`}
        >
          <span className={`absolute top-1 h-5 w-5 rounded-full bg-white shadow transition-all ${isPublic ? "left-6" : "left-1"}`} />
        </button>
      </div>
      <div className="mt-5 flex flex-col gap-2 sm:flex-row">
        <div className="flex min-w-0 flex-1 items-center rounded-xl border border-border bg-background px-3 py-2.5 text-sm">
          <span className="truncate text-muted">{host}/</span>
          <span className="truncate font-medium text-foreground">pro/{username}</span>
        </div>
        <button type="button" onClick={copy}
          className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
          {copied ? <Check className="h-4 w-4" aria-hidden /> : <Copy className="h-4 w-4" aria-hidden />}
          {copied ? "Copied" : "Copy link"}
        </button>
        <a href={path} target="_blank" rel="noopener"
          className="inline-flex items-center justify-center gap-1.5 rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-deep">
          {isPublic ? "View page" : "Preview"}
        </a>
      </div>
      {msg && <div className="mt-3"><Notice tone={msg.tone}>{msg.text}</Notice></div>}
    </section>
  );
}

/** Wide banner image at the top of the page. */
export function CoverCard({ userId, coverUrl }: { userId: string; coverUrl: string | null }) {
  const router = useRouter();
  const [msg, setMsg] = useState<Msg>();
  const [busy, setBusy] = useState(false);

  async function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setMsg(undefined);
    setBusy(true);
    try {
      const path = await uploadProfileCover(file, userId);
      const r = await setCover(path);
      if (r.error) setMsg({ tone: "error", text: r.error });
      else router.refresh();
    } catch (err) {
      setMsg({ tone: "error", text: err instanceof Error ? err.message : "Upload failed. Please try again." });
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!confirm("Remove your cover image?")) return;
    setBusy(true);
    const r = await setCover(null);
    setBusy(false);
    if (r.error) setMsg({ tone: "error", text: r.error });
    else router.refresh();
  }

  return (
    <section id="cover" className="scroll-mt-24 overflow-hidden rounded-3xl border border-border bg-card">
      <div className="relative aspect-[3/1] w-full bg-panel">
        {coverUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={coverUrl} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center bg-gradient-to-br from-[#3b0f6e] via-[#5b21b6] to-[#241045] text-sm text-white/70">
            No cover yet
          </div>
        )}
        {busy && <div className="absolute inset-0 flex items-center justify-center bg-black/40 text-sm text-white">Uploading…</div>}
      </div>
      <div className="flex flex-wrap items-center justify-between gap-3 p-6 sm:px-8">
        <div>
          <h2 className="text-lg font-semibold text-brand-strong">Cover image</h2>
          <p className="text-sm text-muted">A wide photo of your work or workspace. Best at 1500 × 500 or larger.</p>
        </div>
        <div className="flex gap-2">
          <label className={`inline-flex cursor-pointer items-center gap-1.5 rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-deep ${busy ? "pointer-events-none opacity-60" : ""}`}>
            <ImagePlus className="h-4 w-4" aria-hidden />
            {coverUrl ? "Replace" : "Upload cover"}
            <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" onChange={onFile} disabled={busy} />
          </label>
          {coverUrl && (
            <button type="button" onClick={remove} disabled={busy} aria-label="Remove cover"
              className="rounded-xl border border-border px-3 py-2.5 text-muted hover:text-red-700">
              <Trash2 className="h-4 w-4" aria-hidden />
            </button>
          )}
        </div>
      </div>
      {msg && <div className="px-6 pb-6 sm:px-8"><Notice tone={msg.tone}>{msg.text}</Notice></div>}
    </section>
  );
}

const SKILL_IDEAS = ["Brand identity", "UI/UX design", "Web development", "Photography", "Video editing", "Copywriting",
  "Social media", "Makeup", "Tailoring", "Plumbing", "Electrical wiring", "Interior décor", "Event planning"];
const LANGUAGE_IDEAS = ["English", "Yoruba", "Igbo", "Hausa", "Nigerian Pidgin", "French"];

export function SkillsCard({ skills, languages }: { skills: string[]; languages: string[] }) {
  const router = useRouter();
  const [s, setS] = useState(skills);
  const [l, setL] = useState(languages);
  const [msg, setMsg] = useState<Msg>();
  const [pending, start] = useTransition();
  const dirty = JSON.stringify(s) !== JSON.stringify(skills) || JSON.stringify(l) !== JSON.stringify(languages);

  return (
    <section id="skills" className="scroll-mt-24 space-y-5 rounded-3xl border border-border bg-card p-6 sm:p-8">
      <div>
        <h2 className="text-lg font-semibold text-brand-strong">Skills & languages</h2>
        <p className="text-sm text-muted">Customers search by skill, so use the words they would type.</p>
      </div>
      <TagInput id="skills-input" label="Skills" value={s} onChange={setS} max={PRO_LIMITS.skills} maxLength={PRO_LIMITS.skillLength}
        placeholder="Type a skill and press Enter" hint="The first three appear at the top of your page." suggestions={SKILL_IDEAS} />
      <TagInput id="languages-input" label="Languages" value={l} onChange={setL} max={PRO_LIMITS.languages}
        maxLength={PRO_LIMITS.languageLength} placeholder="Add a language" suggestions={LANGUAGE_IDEAS} />
      {msg && <Notice tone={msg.tone}>{msg.text}</Notice>}
      <button
        type="button"
        disabled={!dirty || pending}
        onClick={() =>
          start(async () => {
            setMsg(undefined);
            const r = await saveSkillsAndLanguages(s, l);
            if (r.error) return setMsg({ tone: "error", text: r.error });
            setMsg({ tone: "success", text: "Saved." });
            router.refresh();
          })
        }
        className="rounded-xl bg-brand px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-deep disabled:opacity-50"
      >
        {pending ? "Saving…" : "Save skills & languages"}
      </button>
    </section>
  );
}
