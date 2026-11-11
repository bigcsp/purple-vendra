"use client";

import { createClient } from "@/lib/supabase/client";
import { supabaseKey, supabaseUrl } from "@/lib/supabase/env";
import { compressImage } from "@/lib/upload";

/** The converted video must fit the story-media bucket (50 MB) and the table (≤ 180 s). */
export const MAX_VIDEO_BYTES = 50 * 1024 * 1024;
/** What sellers may pick from their phone before we convert it. */
export const MAX_SOURCE_BYTES = 300 * 1024 * 1024;
export const MAX_VIDEO_SECONDS = 90;
export const VIDEO_TYPES = ["video/mp4", "video/webm", "video/quicktime", "video/x-m4v", "video/3gpp", "video/x-matroska"];

/** width/height are 0 when this browser can't decode the picture (e.g. HEVC/H.265). */
export type VideoInfo = { duration: number; width: number; height: number };

/** Checks the picked file before converting it. */
export async function checkVideo(file: File): Promise<VideoInfo> {
  const looksLikeVideo = VIDEO_TYPES.includes(file.type) || file.type.startsWith("video/") || /\.(mp4|mov|m4v|webm|3gp|mkv)$/i.test(file.name);
  if (!looksLikeVideo) throw new Error("Please choose a video file (MP4, MOV or WebM).");
  if (file.size > MAX_SOURCE_BYTES)
    throw new Error(`That video is ${(file.size / 1024 / 1024).toFixed(0)} MB. Please trim it or pick one under 300 MB.`);
  const info = await readVideoInfo(file).catch(() => ({ duration: 0, width: 0, height: 0 }));
  if (info.duration && info.duration > MAX_VIDEO_SECONDS + 0.5)
    throw new Error(`Stories can be up to ${MAX_VIDEO_SECONDS} seconds. This one is ${Math.round(info.duration)} seconds. Trim it, then try again.`);
  return info;
}

export function readVideoInfo(file: Blob): Promise<VideoInfo> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const video = document.createElement("video");
    video.preload = "metadata";
    video.muted = true;
    const timer = setTimeout(() => {
      URL.revokeObjectURL(url);
      reject(new Error("timeout"));
    }, 15000);
    video.onloadedmetadata = () => {
      clearTimeout(timer);
      resolve({ duration: video.duration, width: video.videoWidth, height: video.videoHeight });
      URL.revokeObjectURL(url);
    };
    video.onerror = () => {
      clearTimeout(timer);
      URL.revokeObjectURL(url);
      reject(new Error("Your browser can't open this video."));
    };
    video.src = url;
  });
}

/**
 * Converts any phone video to H.264 + AAC MP4, longest side max 1280px,
 * with the index at the start (+faststart) so it starts playing quickly.
 * H.264 MP4 plays on every phone and browser, unlike HEVC/H.265 (the
 * default on recent iPhones and many Androids) which shows a blank picture
 * on Windows, many Androids and older browsers. Runs in the seller's
 * browser with ffmpeg.wasm (served from /ffmpeg, copied on npm install).
 */
export async function convertForStories(file: File, onProgress?: (percent: number) => void): Promise<Blob> {
  // Loaded at runtime from /ffmpeg (copied there on npm install), not bundled:
  // Next's bundler can't follow how ffmpeg.wasm starts its worker.
  const base = `${window.location.origin}/ffmpeg`;
  type FFmpegInstance = {
    load(cfg: { coreURL: string; wasmURL: string; classWorkerURL: string }): Promise<boolean>;
    on(event: "progress", cb: (e: { progress: number }) => void): void;
    writeFile(path: string, data: Uint8Array): Promise<boolean>;
    readFile(path: string): Promise<Uint8Array | string>;
    exec(args: string[]): Promise<number>;
    terminate(): void;
  };
  let ffmpeg: FFmpegInstance;
  try {
    const mod = (await import(/* webpackIgnore: true */ /* turbopackIgnore: true */ `${base}/classes.js`)) as {
      FFmpeg: new () => FFmpegInstance;
    };
    ffmpeg = new mod.FFmpeg();
    await ffmpeg.load({
      coreURL: `${base}/ffmpeg-core.js`,
      wasmURL: `${base}/ffmpeg-core.wasm`,
      classWorkerURL: `${base}/worker.js`,
    });
  } catch {
    throw new Error("Couldn't start the video converter. Check your connection and try again.");
  }
  ffmpeg.on("progress", ({ progress }) => {
    if (onProgress && progress >= 0 && progress <= 1) onProgress(Math.round(progress * 100));
  });

  const ext = (file.name.match(/\.([a-z0-9]+)$/i)?.[1] ?? "mp4").toLowerCase();
  const input = `input.${ext}`;
  try {
    await ffmpeg.writeFile(input, new Uint8Array(await file.arrayBuffer()));
    const code = await ffmpeg.exec([
      "-i", input,
      "-t", String(MAX_VIDEO_SECONDS),
      "-map", "0:v:0", "-map", "0:a:0?",
      "-vf", "scale=w=1280:h=1280:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p",
      "-c:v", "libx264", "-preset", "veryfast", "-crf", "26", "-profile:v", "main", "-r", "30",
      "-c:a", "aac", "-b:a", "128k", "-ac", "2",
      "-movflags", "+faststart",
      "output.mp4",
    ]);
    if (code !== 0) throw new Error("convert");
    const data = await ffmpeg.readFile("output.mp4");
    if (typeof data === "string" || data.byteLength < 1000) throw new Error("convert");
    const blob = new Blob([data.slice().buffer as ArrayBuffer], { type: "video/mp4" });
    if (blob.size > MAX_VIDEO_BYTES) throw new Error("That video is still over 50 MB after converting. Please trim it.");
    return blob;
  } catch (err) {
    if (err instanceof Error && err.message !== "convert") throw err;
    throw new Error("We couldn't convert this video. Try exporting it again from your gallery, or record a new one.");
  } finally {
    ffmpeg.terminate();
  }
}

/** Takes a frame (about 1 second in) as the cover picture, saved as WebP. */
export function captureCover(file: Blob, atSeconds = 1): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const video = document.createElement("video");
    video.muted = true;
    video.playsInline = true;
    video.preload = "auto";
    const fail = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Couldn't make a cover picture. Upload one instead."));
    };
    video.onerror = fail;
    video.onloadedmetadata = () => {
      video.currentTime = Math.min(atSeconds, Math.max(0, video.duration / 3));
    };
    video.onseeked = () => {
      const scale = Math.min(1, 720 / Math.max(video.videoWidth, video.videoHeight));
      const canvas = document.createElement("canvas");
      canvas.width = Math.round(video.videoWidth * scale);
      canvas.height = Math.round(video.videoHeight * scale);
      const ctx = canvas.getContext("2d");
      if (!ctx) return fail();
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(
        (blob) => {
          URL.revokeObjectURL(url);
          if (blob) resolve(blob);
          else reject(new Error("Couldn't make a cover picture. Upload one instead."));
        },
        "image/webp",
        0.8,
      );
    };
    video.src = url;
  });
}

/** Shrinks an uploaded cover picture (max 1080px, WebP). */
export function shrinkCover(file: File) {
  return compressImage(file, 1080, 0.82);
}

/**
 * Uploads to the story-media bucket with a live progress callback (0–100).
 * Uses the Storage REST endpoint directly because supabase-js upload()
 * doesn't report progress. The database rules still apply: own folder,
 * seller with 2FA, 50 MB, allowed types only.
 */
export async function uploadStoryFile(
  path: string,
  body: Blob,
  contentType: string,
  onProgress?: (percent: number) => void,
): Promise<string> {
  const {
    data: { session },
  } = await createClient().auth.getSession();
  if (!session) throw new Error("Your session has ended. Please sign in again.");

  const safePath = path.split("/").map(encodeURIComponent).join("/");
  await new Promise<void>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("POST", `${supabaseUrl}/storage/v1/object/story-media/${safePath}`);
    xhr.setRequestHeader("Authorization", `Bearer ${session.access_token}`);
    xhr.setRequestHeader("apikey", supabaseKey);
    xhr.setRequestHeader("Content-Type", contentType);
    xhr.setRequestHeader("cache-control", "max-age=31536000");
    xhr.setRequestHeader("x-upsert", "false");
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable && onProgress) onProgress(Math.round((e.loaded / e.total) * 100));
    };
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) return resolve();
      reject(new Error(friendlyUploadError(xhr.status, xhr.responseText)));
    };
    xhr.onerror = () => reject(new Error("Upload failed. Check your connection and try again."));
    xhr.send(body);
  });
  return path;
}

function friendlyUploadError(status: number, body: string) {
  if (status === 413 || /size|too large/i.test(body)) return "That file is over 50 MB. Please trim the video.";
  if (status === 401 || status === 403 || /row-level security|unauthorized/i.test(body))
    return "Upload not allowed. Make sure you're signed in with your 2FA code, then try again.";
  if (/mime|type/i.test(body)) return "That file type isn't allowed. Use MP4, WebM or MOV.";
  return "Upload failed. Check your connection and try again.";
}

