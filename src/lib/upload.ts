"use client";

import { createClient } from "@/lib/supabase/client";

/** Supabase bucket limit is 5 MB per file. */
export const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];

/**
 * Shrinks a phone photo before upload: longest side max 1600px, saved as
 * WebP. A typical 4–8 MB phone photo becomes ~200–500 KB, which uploads
 * fast on mobile data and keeps listing pages quick.
 */
export async function compressImage(file: File, maxSide = 1600, quality = 0.82): Promise<Blob> {
  if (!IMAGE_TYPES.includes(file.type)) throw new Error("Please choose a JPG, PNG or WebP photo.");

  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
  const width = Math.round(bitmap.width * scale);
  const height = Math.round(bitmap.height * scale);

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Your browser couldn't process this photo.");
  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/webp", quality));
  if (!blob) throw new Error("Your browser couldn't process this photo.");
  return blob;
}

function randomName() {
  return `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
}

/**
 * Uploads an ID document to the PRIVATE id-documents bucket, in the
 * seller's own folder. Photos are compressed (but kept sharp enough to
 * read); PDFs are uploaded as they are. Returns the storage path.
 */
export async function uploadIdDocument(file: File, userId: string): Promise<string> {
  let body: Blob = file;
  let ext = "pdf";
  let contentType = "application/pdf";

  if (file.type !== "application/pdf") {
    body = await compressImage(file, 2200, 0.9);
    ext = "webp";
    contentType = "image/webp";
  }
  if (body.size > MAX_UPLOAD_BYTES) throw new Error("That file is over 5 MB. Try a smaller photo or PDF.");

  const path = `${userId}/${randomName()}.${ext}`;
  const { error } = await createClient()
    .storage.from("id-documents")
    .upload(path, body, { contentType, upsert: false });
  if (error) throw new Error(friendlyStorageError(error.message));
  return path;
}

/**
 * Uploads a listing photo to the PUBLIC listing-images bucket.
 * Used by the listing editor in step 5. Returns the storage path.
 */
export async function uploadListingPhoto(file: File, userId: string, listingId: string): Promise<string> {
  const body = await compressImage(file);
  const path = `${userId}/${listingId}/${randomName()}.webp`;
  const { error } = await createClient()
    .storage.from("listing-images")
    .upload(path, body, { contentType: "image/webp", cacheControl: "31536000", upsert: false });
  if (error) throw new Error(friendlyStorageError(error.message));
  return path;
}

function friendlyStorageError(message: string) {
  if (/row-level security|unauthorized|403/i.test(message))
    return "Upload not allowed. Make sure you're signed in with your 2FA code, then try again.";
  if (/size|too large|413/i.test(message)) return "That file is over 5 MB. Try a smaller one.";
  if (/mime|type/i.test(message)) return "That file type isn't allowed. Use JPG, PNG, WebP or PDF.";
  return "Upload failed. Check your connection and try again.";
}
