"use client";

import { useState, useTransition } from "react";
import { submitVerification } from "@/app/actions/verification";
import { Notice, buttonClass } from "@/components/ui";
import { ID_TYPES, type IdType } from "@/lib/id-types";
import { MAX_UPLOAD_BYTES, uploadIdDocument } from "@/lib/upload";

export function VerifyIdForm({ userId, currentType }: { userId: string; currentType: IdType | null }) {
  const [idType, setIdType] = useState<IdType | "">(currentType ?? "");
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState<string>();
  const [step, setStep] = useState<"idle" | "uploading" | "saving">("idle");
  const [, startTransition] = useTransition();

  function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    const chosen = e.target.files?.[0] ?? null;
    setError(undefined);
    if (chosen && chosen.type === "application/pdf" && chosen.size > MAX_UPLOAD_BYTES) {
      setError("That PDF is over 5 MB. Try a photo of your ID instead.");
      setFile(null);
      return;
    }
    setFile(chosen);
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!idType) return setError("Choose the type of ID.");
    if (!file) return setError("Choose a photo or PDF of your ID.");
    setError(undefined);

    try {
      setStep("uploading");
      const path = await uploadIdDocument(file, userId);
      setStep("saving");
      startTransition(async () => {
        const result = await submitVerification(idType, path);
        if (result?.error) {
          setError(result.error);
          setStep("idle");
        }
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed. Please try again.");
      setStep("idle");
    }
  }

  const busy = step !== "idle";

  return (
    <form onSubmit={onSubmit} className="space-y-5">
      <fieldset>
        <legend className="text-sm font-medium text-brand-strong">Type of ID</legend>
        <div className="mt-2 grid gap-2 sm:grid-cols-2">
          {(Object.keys(ID_TYPES) as IdType[]).map((key) => (
            <label
              key={key}
              className={`flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-2.5 text-sm ${
                idType === key ? "border-brand bg-brand-soft" : "border-border bg-card"
              }`}
            >
              <input
                type="radio"
                name="id_type"
                value={key}
                checked={idType === key}
                onChange={() => setIdType(key)}
                className="accent-[var(--brand)]"
              />
              {ID_TYPES[key]}
            </label>
          ))}
        </div>
      </fieldset>

      <label className="block">
        <span className="text-sm font-medium text-brand-strong">Photo or PDF of your ID</span>
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp,application/pdf"
          onChange={onFile}
          className="mt-2 block w-full rounded-xl border border-dashed border-border bg-card p-3 text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-brand-soft file:px-3 file:py-1.5 file:font-medium file:text-brand"
        />
        <span className="mt-1 block text-xs text-muted">
          Take a clear photo in good light with all four corners showing. JPG, PNG, WebP or PDF, up to 5 MB.
        </span>
      </label>

      {error && <Notice tone="error">{error}</Notice>}

      <button className={buttonClass} disabled={busy}>
        {step === "uploading" ? "Uploading securely…" : step === "saving" ? "Submitting…" : "Submit for review"}
      </button>
      <p className="text-center text-xs text-muted">
        🔒 Your ID is stored privately. Only you and the Purple Shop review team can see it.
      </p>
    </form>
  );
}
