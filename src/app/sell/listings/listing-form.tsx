"use client";

import { X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import {
  addListingPhotos,
  createListing,
  deleteListing,
  removeListingPhoto,
  updateListing,
  type ListingInput,
} from "@/server/actions/listings";
import { Notice, buttonClass } from "@/components/ui";
import { NIGERIAN_STATES } from "@/lib/nigeria";
import { publicFileUrl } from "@/lib/storage-url";
import { uploadListingPhoto } from "@/lib/upload";

type Option = { id: number; name: string; section: string };
type Photo = { id: string; storage_path: string };

export type ListingFormValues = Omit<ListingInput, "submit"> & { id?: string; status?: string };

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

export function ListingForm({
  userId,
  categories,
  initial,
  photos = [],
}: {
  userId: string;
  categories: Option[];
  initial?: ListingFormValues;
  photos?: Photo[];
}) {
  const router = useRouter();
  const [values, setValues] = useState<ListingFormValues>(
    initial ?? {
      title: "",
      description: "",
      type: "product",
      categoryId: categories[0]?.id ?? 0,
      price: "",
      priceIsStarting: false,
      deliveryMode: "delivery",
      state: "",
      city: "",
      stock: "",
    },
  );
  const [existing, setExisting] = useState(photos);
  const [files, setFiles] = useState<File[]>([]);
  const [error, setError] = useState<string>();
  const [busy, setBusy] = useState<string>();

  const set = <K extends keyof ListingFormValues>(key: K, value: ListingFormValues[K]) =>
    setValues((v) => ({ ...v, [key]: value }));

  async function save(submit: boolean) {
    setError(undefined);
    if (existing.length + files.length === 0 && submit) return setError("Add at least one photo.");
    if (existing.length + files.length > 6) return setError("Up to 6 photos per listing.");
    try {
      setBusy("Saving…");
      const input = { ...values, submit };
      const result = values.id ? await updateListing(values.id, input) : await createListing(input);
      if (result.error || !result.id) throw new Error(result.error ?? "Couldn't save.");
      if (files.length) {
        const paths: string[] = [];
        for (let i = 0; i < files.length; i++) {
          setBusy(`Uploading photo ${i + 1} of ${files.length}…`);
          paths.push(await uploadListingPhoto(files[i], userId, result.id));
        }
        const added = await addListingPhotos(result.id, paths);
        if (added.error) throw new Error(added.error);
      }
      router.push("/sell/listings?saved=1");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't save. Please try again.");
      setBusy(undefined);
    }
  }

  async function removePhoto(id: string) {
    const result = await removeListingPhoto(id);
    if (result.error) return setError(result.error);
    setExisting((p) => p.filter((x) => x.id !== id));
  }

  async function remove() {
    if (!values.id || !confirm("Delete this listing? This can't be undone.")) return;
    setBusy("Deleting…");
    const result = await deleteListing(values.id);
    if (result.error) {
      setError(result.error);
      setBusy(undefined);
      return;
    }
    router.push("/sell/listings");
    router.refresh();
  }

  return (
    <form onSubmit={(e) => e.preventDefault()} className="space-y-5">
      <label className="block">
        <span className="text-sm font-medium text-brand-strong">Title</span>
        <input className={inputClass} value={values.title} maxLength={120} required
          onChange={(e) => set("title", e.target.value)} placeholder="Hand-dyed Adire two-piece" />
      </label>
      <label className="block">
        <span className="text-sm font-medium text-brand-strong">Description</span>
        <textarea className={inputClass} rows={5} value={values.description} maxLength={5000}
          onChange={(e) => set("description", e.target.value)}
          placeholder="Materials, sizes, how long it takes, what's included" />
      </label>

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">What are you selling?</span>
          <select className={inputClass} value={values.type} onChange={(e) => set("type", e.target.value)}>
            <option value="product">A product</option>
            <option value="service">A service</option>
            <option value="talent">Talent (modelling, MUA, performing)</option>
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Category</span>
          <select className={inputClass} value={values.categoryId}
            onChange={(e) => set("categoryId", Number(e.target.value))}>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>{c.section} · {c.name}</option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Price (₦)</span>
          <input className={inputClass} inputMode="decimal" value={values.price}
            onChange={(e) => set("price", e.target.value)} placeholder="15,000" />
          <span className="mt-1 flex items-center gap-2 text-xs text-muted">
            <input type="checkbox" checked={values.priceIsStarting} className="accent-[var(--brand)]"
              onChange={(e) => set("priceIsStarting", e.target.checked)} />
            This is a starting price
          </span>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">How buyers get it</span>
          <select className={inputClass} value={values.deliveryMode} onChange={(e) => set("deliveryMode", e.target.value)}>
            <option value="delivery">Delivery</option>
            <option value="pickup">Pickup</option>
            <option value="digital">Digital download</option>
            <option value="in_person_service">In-person service</option>
            <option value="remote_service">Remote service</option>
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">State</span>
          <select className={inputClass} value={values.state} onChange={(e) => set("state", e.target.value)}>
            <option value="">Choose…</option>
            {NIGERIAN_STATES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">City or area</span>
          <input className={inputClass} value={values.city} maxLength={80}
            onChange={(e) => set("city", e.target.value)} placeholder="Ikeja" />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Stock (optional)</span>
          <input className={inputClass} inputMode="numeric" value={values.stock}
            onChange={(e) => set("stock", e.target.value)} placeholder="Leave empty for made-to-order" />
        </label>
      </div>

      <div>
        <span className="text-sm font-medium text-brand-strong">Photos (up to 6)</span>
        {existing.length > 0 && (
          <div className="mt-2 flex flex-wrap gap-2">
            {existing.map((p) => (
              <div key={p.id} className="relative">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={publicFileUrl("listing-images", p.storage_path) ?? ""} alt=""
                  className="h-20 w-20 rounded-xl object-cover" />
                <button type="button" onClick={() => removePhoto(p.id)}
                  aria-label="Remove photo"
                  className="absolute -right-1 -top-1 flex h-6 w-6 items-center justify-center rounded-full bg-card text-red-600 shadow"><X className="h-3.5 w-3.5" strokeWidth={2.25} aria-hidden /></button>
              </div>
            ))}
          </div>
        )}
        <input type="file" multiple accept="image/jpeg,image/png,image/webp"
          onChange={(e) => setFiles(Array.from(e.target.files ?? []))}
          className="mt-2 block w-full rounded-xl border border-dashed border-border bg-card p-3 text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-brand-soft file:px-3 file:py-1.5 file:font-medium file:text-brand" />
        <span className="mt-1 block text-xs text-muted">JPG, PNG or WebP. We shrink them for fast loading.</span>
      </div>

      {error && <Notice tone="error">{error}</Notice>}

      <div className="flex flex-wrap gap-2">
        <button type="button" onClick={() => save(true)} className={`${buttonClass} sm:w-auto`} disabled={!!busy}>
          {busy ?? (values.status === "approved" ? "Save changes" : "Submit for review")}
        </button>
        {values.status !== "approved" && (
          <button type="button" onClick={() => save(false)} disabled={!!busy}
            className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft">
            Save as draft
          </button>
        )}
        {values.id && (
          <button type="button" onClick={remove} disabled={!!busy}
            className="ml-auto px-3 text-sm text-red-600 hover:underline">
            Delete listing
          </button>
        )}
      </div>
      <p className="text-xs text-muted">
        New listings are checked by the Purple Shop team before they go live. Editing the title, price,
        description or category of a live listing sends it back for a quick review.
      </p>
    </form>
  );
}
