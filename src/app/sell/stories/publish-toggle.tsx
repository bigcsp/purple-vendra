"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { setStoryPublished } from "@/app/actions/stories";

export function PublishToggle({ id, published }: { id: string; published: boolean }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [error, setError] = useState<string>();
  return (
    <>
      <button
        disabled={pending}
        onClick={() =>
          start(async () => {
            const r = await setStoryPublished(id, !published);
            if (r.error) setError(r.error);
            else router.refresh();
          })
        }
        className="text-brand hover:underline disabled:opacity-60"
      >
        {pending ? "…" : published ? "Unpublish" : "Publish"}
      </button>
      {error && <span className="w-full text-red-700">{error}</span>}
    </>
  );
}
