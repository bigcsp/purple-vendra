import { supabaseUrl } from "@/lib/supabase/env";

/** Public link to a file in a public bucket (listing-images, story-media). */
export function publicFileUrl(bucket: "listing-images" | "story-media", path: string | null | undefined) {
  if (!path) return null;
  const safe = path.split("/").map(encodeURIComponent).join("/");
  return `${supabaseUrl}/storage/v1/object/public/${bucket}/${safe}`;
}
