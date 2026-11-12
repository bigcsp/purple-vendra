"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { createStory, deleteStory, updateStory } from "@/app/actions/stories";
import { Notice, buttonClass } from "@/components/ui";
import { formatNaira } from "@/lib/money";
import {
  MAX_VIDEO_SECONDS,
  captureCover,
  checkVideo,
  convertForStories,
  readVideoInfo,
  shrinkCover,
  uploadStoryFile,
  type VideoInfo,
} from "@/lib/story-media";
import { publicFileUrl } from "@/lib/storage-url";

type Category = { id: number; name: string; section: string };
type MyListing = { id: string; title: string; price_kobo: number; status: string; image: string | null };

export type StoryFormInitial = {
  id: string;
  title: string;
  description: string;
  categoryId: number;
  videoPath: string;
  thumbnailPath: string | null;
  durationSeconds: number | null;
  sizeBytes: number | null;
  width: number | null;
  height: number | null;
  productIds: string[];
  status: string;
};

const inputClass =
  "mt-1 block w-full rounded-xl border border-border bg-card px-3 py-2.5 outline-none focus:border-brand focus:ring-2 focus:ring-brand-soft";

export function StoryForm({
  userId,
  categories,
  listings,
  initial,
}: {
  userId: string;
  categories: Category[];
  listings: MyListing[];
  initial?: StoryFormInitial;
}) {
  const router = useRouter();
  const [storyId] = useState(() => initial?.id ?? crypto.randomUUID());
  const [title, setTitle] = useState(initial?.title ?? "");
  const [description, setDescription] = useState(initial?.description ?? "");
  const [categoryId, setCategoryId] = useState(initial?.categoryId ?? categories[0]?.id ?? 0);
  const [productIds, setProductIds] = useState<string[]>(initial?.productIds ?? []);

  const [video, setVideo] = useState<Blob | null>(null);
  const [originalSize, setOriginalSize] = useState<number | null>(null);
  const [info, setInfo] = useState<VideoInfo | null>(null);
  const [autoCover, setAutoCover] = useState<Blob | null>(null);
  const [customCover, setCustomCover] = useState<File | null>(null);

  const [error, setError] = useState<string>();
  const [stage, setStage] = useState<string>();
  const [progress, setProgress] = useState<number | null>(null);

  const previewUrl = useMemo(
    () => (video ? URL.createObjectURL(video) : publicFileUrl("story-media", initial?.videoPath)),
    [video, initial?.videoPath],
  );
  const coverUrl = useMemo(() => {
    if (customCover) return URL.createObjectURL(customCover);
    if (autoCover) return URL.createObjectURL(autoCover);
    return publicFileUrl("story-media", initial?.thumbnailPath);
  }, [customCover, autoCover, initial?.thumbnailPath]);
  useEffect(() => () => { if (video && previewUrl) URL.revokeObjectURL(previewUrl); }, [video, previewUrl]);

  async function onVideo(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    setError(undefined);
    if (!file) return;
    try {
      setStage("Checking your video…");
      await checkVideo(file);
      // Always convert to H.264 MP4 so the picture plays on every phone and
      // browser (phones often record HEVC, which shows a blank picture elsewhere).
      setStage("Converting so it plays on every phone");
      setProgress(0);
      const converted = await convertForStories(file, setProgress);
      setProgress(null);
      setStage("Making a cover picture…");
      const convertedInfo = await readVideoInfo(converted);
      if (!convertedInfo.width) throw new Error("We couldn't read the converted video. Try another file.");
      setVideo(converted);
      setOriginalSize(file.size);
      setInfo(convertedInfo);
      setAutoCover(await captureCover(converted).catch(() => null));
    } catch (err) {
      setError(err instanceof Error ? err.message : "That video can't be used.");
    } finally {
      setStage(undefined);
      setProgress(null);
    }
  }

  function toggleProduct(id: string) {
    setProductIds((ids) =>
      ids.includes(id) ? ids.filter((x) => x !== id) : ids.length >= 6 ? ids : [...ids, id],
    );
  }

  async function save(publish: boolean) {
    setError(undefined);
    if (!initial && !video) return setError("Choose a video first.");
    if (title.trim().length < 3) return setError("Add a title (at least 3 characters).");
    try {
      let videoPath = initial?.videoPath ?? "";
      let thumbnailPath = initial?.thumbnailPath ?? null;
      const stamp = Date.now();

      if (video) {
        setStage("Uploading video");
        setProgress(0);
        videoPath = await uploadStoryFile(
          `${userId}/${storyId}/video-${stamp}.mp4`,
          video,
          "video/mp4",
          setProgress,
        );
        setProgress(null);
      }
      const coverBlob = customCover ? await shrinkCover(customCover) : video ? autoCover : null;
      if (coverBlob) {
        setStage("Uploading cover");
        thumbnailPath = await uploadStoryFile(`${userId}/${storyId}/cover-${stamp}.webp`, coverBlob, "image/webp");
      }

      setStage(publish ? "Publishing…" : "Saving…");
      const payload = {
        id: storyId,
        title,
        description,
        categoryId,
        videoPath,
        thumbnailPath,
        durationSeconds: info?.duration ?? initial?.durationSeconds ?? null,
        sizeBytes: video?.size ?? initial?.sizeBytes ?? null,
        width: info?.width ?? initial?.width ?? null,
        height: info?.height ?? initial?.height ?? null,
        productIds,
        publish,
      };
      const result = initial ? await updateStory(payload) : await createStory(payload);
      if (result.error && !result.id) throw new Error(result.error);
      router.push(`/sell/stories?saved=${publish ? "published" : "draft"}${result.error ? "&warn=products" : ""}`);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't save. Please try again.");
      setStage(undefined);
      setProgress(null);
    }
  }

  async function remove() {
    if (!initial || !confirm("Delete this story? Views, likes and comments on it will be lost.")) return;
    setStage("Deleting…");
    const r = await deleteStory(initial.id);
    if (r.error) {
      setError(r.error);
      setStage(undefined);
      return;
    }
    router.push("/sell/stories");
    router.refresh();
  }

  const busy = !!stage;
  const locked = initial && (initial.status === "hidden" || initial.status === "removed");

  return (
    <form onSubmit={(e) => e.preventDefault()} className="grid gap-6 md:grid-cols-[240px_1fr]">
      {/* Preview, phone-shaped like it will look to buyers */}
      <div>
        <div className="relative mx-auto aspect-[9/16] w-full max-w-[240px] overflow-hidden rounded-3xl bg-panel">
          {previewUrl ? (
            <video key={previewUrl} src={previewUrl} poster={coverUrl ?? undefined} controls playsInline
              className="h-full w-full object-cover" />
          ) : (
            <label className="flex h-full cursor-pointer flex-col items-center justify-center gap-2 p-4 text-center text-white/90">
              <span className="text-4xl">🎬</span>
              <span className="text-sm font-medium">Choose a video</span>
              <span className="text-xs text-white/70">Any phone video · up to {MAX_VIDEO_SECONDS}s</span>
              <input type="file" accept="video/*" onChange={onVideo} className="sr-only" disabled={busy} />
            </label>
          )}
        </div>
        {previewUrl && !locked && (
          <label className="mt-2 block cursor-pointer text-center text-sm font-medium text-brand hover:underline">
            {initial ? "Replace video" : "Choose a different video"}
            <input type="file" accept="video/*" onChange={onVideo} className="sr-only" disabled={busy} />
          </label>
        )}
        {info && (
          <p className="mt-1 text-center text-xs text-muted">
            {Math.round(info.duration)}s · {info.width}×{info.height} · {((video?.size ?? 0) / 1024 / 1024).toFixed(1)} MB
            {originalSize ? ` (was ${(originalSize / 1024 / 1024).toFixed(1)} MB)` : ""} · ready for all phones
          </p>
        )}
        {previewUrl && (
          <div className="mt-3">
            <span className="text-xs font-medium text-brand-strong">Cover picture</span>
            <div className="mt-1 flex items-center gap-2">
              {coverUrl && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={coverUrl} alt="" className="h-16 w-10 rounded-lg object-cover" />
              )}
              <label className="cursor-pointer text-xs text-brand hover:underline">
                Upload your own
                <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only"
                  onChange={(e) => setCustomCover(e.target.files?.[0] ?? null)} />
              </label>
            </div>
          </div>
        )}
      </div>

      <div className="space-y-4">
        {initial && !video && !initial.width && (
          <Notice tone="error">
            This video was uploaded in a format many phones can&apos;t show (only the sound plays). Tap
            &quot;Replace video&quot; and choose the same file again. We&apos;ll convert it so it plays everywhere, then
            click Save changes.
          </Notice>
        )}
        {locked && (
          <Notice tone="error">This story is under review by the Purple Shop team, so it can&apos;t be published right now.</Notice>
        )}
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Title</span>
          <input className={inputClass} value={title} maxLength={120} onChange={(e) => setTitle(e.target.value)}
            placeholder="How I tie-dye a 3-piece Adire set" />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Description</span>
          <textarea className={inputClass} rows={3} value={description} maxLength={2000}
            onChange={(e) => setDescription(e.target.value)} placeholder="Tell buyers the story behind it" />
        </label>
        <label className="block">
          <span className="text-sm font-medium text-brand-strong">Category</span>
          <select className={inputClass} value={categoryId} onChange={(e) => setCategoryId(Number(e.target.value))}>
            {categories.map((c) => <option key={c.id} value={c.id}>{c.section} · {c.name}</option>)}
          </select>
        </label>

        <fieldset>
          <legend className="text-sm font-medium text-brand-strong">
            Products in this video <span className="font-normal text-muted">({productIds.length}/6)</span>
          </legend>
          {listings.length === 0 ? (
            <p className="mt-1 text-sm text-muted">
              You have no listings yet. <Link href="/sell/listings/new" className="text-brand underline">Add one</Link> to make
              this video shoppable.
            </p>
          ) : (
            <div className="mt-2 grid max-h-64 gap-2 overflow-y-auto sm:grid-cols-2">
              {listings.map((l) => (
                <label key={l.id}
                  className={`flex cursor-pointer items-center gap-2 rounded-xl border p-2 text-sm ${
                    productIds.includes(l.id) ? "border-brand bg-brand-soft" : "border-border bg-card"
                  }`}>
                  <input type="checkbox" checked={productIds.includes(l.id)} onChange={() => toggleProduct(l.id)}
                    className="accent-[var(--brand)]" />
                  {l.image ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={l.image} alt="" className="h-9 w-9 rounded-lg object-cover" />
                  ) : (
                    <span className="h-9 w-9 rounded-lg bg-brand-soft" />
                  )}
                  <span className="min-w-0 flex-1">
                    <span className="block truncate">{l.title}</span>
                    <span className="text-xs text-muted">
                      {formatNaira(l.price_kobo)}
                      {l.status !== "approved" && " · shows once approved"}
                    </span>
                  </span>
                </label>
              ))}
            </div>
          )}
        </fieldset>

        {error && <Notice tone="error">{error}</Notice>}

        {stage && (
          <div aria-live="polite">
            <p className="text-sm text-brand-strong">
              {stage}
              {progress !== null && ` · ${progress}%`}
            </p>
            {progress !== null && (
              <div className="mt-1 h-2 overflow-hidden rounded-full bg-brand-soft">
                <div className="h-full bg-brand transition-all" style={{ width: `${progress}%` }} />
              </div>
            )}
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          <button type="button" onClick={() => save(true)} disabled={busy || !!locked} className={`${buttonClass} sm:w-auto`}>
            {initial?.status === "published" ? "Save changes" : "Publish to my shop"}
          </button>
          <button type="button" onClick={() => save(false)} disabled={busy || !!locked}
            className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium text-brand hover:bg-brand-soft disabled:opacity-60">
            {initial?.status === "published" ? "Unpublish (save as draft)" : "Save as draft"}
          </button>
          {initial && (
            <button type="button" onClick={remove} disabled={busy} className="ml-auto px-3 text-sm text-red-600 hover:underline">
              Delete story
            </button>
          )}
        </div>
        <p className="text-xs text-muted">
          Tip: film vertically (9:16) in good light at 720p. Keep it short and show the making, the finish and the price.
          Don&apos;t put phone numbers or bank details in videos; buyers pay safely through Purple Shop.
        </p>
      </div>
    </form>
  );
}
