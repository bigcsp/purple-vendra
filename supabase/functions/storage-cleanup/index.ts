// Purple Vendra — storage-cleanup
//
// Deletes files that the database has queued for deletion
// (public.storage_deletion_queue): ID documents past their retention
// period, replaced uploads, and the files of deleted accounts.
// Supabase only allows file deletion through the Storage API, which is
// why this runs here and not in SQL. Called nightly by pg_cron.
//
// It only ever deletes what is already in the queue, so calling it more
// often does no harm. At most 200 files per run.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BATCH = 200;

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: jobs, error } = await supabase
    .from("storage_deletion_queue")
    .select("id, bucket_id, object_name")
    .is("done_at", null)
    .order("queued_at")
    .limit(BATCH);

  if (error) return Response.json({ ok: false, error: error.message }, { status: 500 });
  if (!jobs?.length) return Response.json({ ok: true, deleted: 0 });

  const byBucket = new Map<string, { id: number; name: string }[]>();
  for (const j of jobs) {
    const list = byBucket.get(j.bucket_id) ?? [];
    list.push({ id: j.id, name: j.object_name });
    byBucket.set(j.bucket_id, list);
  }

  let deleted = 0;
  const failed: string[] = [];
  for (const [bucket, items] of byBucket) {
    const { error: rmError } = await supabase.storage.from(bucket).remove(items.map((i) => i.name));
    const ids = items.map((i) => i.id);
    if (rmError) {
      failed.push(bucket);
      await supabase.from("storage_deletion_queue").update({ last_error: rmError.message }).in("id", ids);
    } else {
      deleted += items.length;
      await supabase
        .from("storage_deletion_queue")
        .update({ done_at: new Date().toISOString(), last_error: null })
        .in("id", ids);
    }
  }

  return Response.json({ ok: failed.length === 0, deleted, failed });
});
