"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, useTransition } from "react";
import { toggleFollow } from "@/app/actions/shop";
import { addStoryProductToCart } from "@/app/actions/stories";
import { ReportButton } from "@/components/report-button";
import { formatNaira } from "@/lib/money";
import type { StoryItem } from "@/lib/stories";
import { createClient } from "@/lib/supabase/client";
import { trackStory } from "./track";

type Comment = { id: string; body: string; created_at: string; user_id: string; display_name: string; username: string; is_seller: boolean };

type ViewerProps = {
  stories: StoryItem[];
  index: number;
  onIndex: (i: number) => void;
  onClose: () => void;
  viewerId: string | null;
};

/** Full-screen player. Each story gets a fresh stage, so likes/panels reset when you swipe. */
export function StoryViewer(props: ViewerProps) {
  return <StoryStage key={props.stories[props.index].id} {...props} />;
}

function StoryStage({
  stories,
  index,
  onIndex,
  onClose,
  viewerId,
}: ViewerProps) {
  const story = stories[index];
  const router = useRouter();
  const path = usePathname();
  const videoRef = useRef<HTMLVideoElement>(null);
  const touchY = useRef<number | null>(null);

  const [playing, setPlaying] = useState(false);
  const [noPicture, setNoPicture] = useState(false);
  const [muted, setMuted] = useState(false);
  const [liked, setLiked] = useState(false);
  const [likes, setLikes] = useState(story.likeCount);
  const [commentCount, setCommentCount] = useState(story.commentCount);
  const [follow, setFollow] = useState<{ followers: number; following: boolean } | null>(null);
  const [panel, setPanel] = useState<"none" | "comments" | "products" | "report">("none");
  const [toast, setToast] = useState<string>();

  const needSignIn = useCallback(() => {
    router.push(`/login?next=${encodeURIComponent(`${path}?story=${story.id}`)}`);
  }, [router, path, story.id]);

  const go = useCallback(
    (delta: number) => {
      const next = index + delta;
      if (next >= 0 && next < stories.length) onIndex(next);
    },
    [index, stories.length, onIndex],
  );

  // Load whether the viewer liked this story and follows the seller.
  useEffect(() => {
    const supabase = createClient();
    if (viewerId) {
      supabase.from("story_likes").select("video_id").eq("video_id", story.id).eq("user_id", viewerId).maybeSingle()
        .then(({ data }) => setLiked(!!data));
    }
    supabase.rpc("seller_follow_info", { p_seller: story.seller.id }).single()
      .then(({ data }) => data && setFollow(data as { followers: number; following: boolean }));
  }, [story.id, story.seller.id, viewerId]);

  // Keyboard: arrows to move, Esc to close, space to pause.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.target as HTMLElement)?.closest("input, textarea")) return;
      if (e.key === "Escape") onClose();
      if (e.key === "ArrowDown" || e.key === "ArrowRight") go(1);
      if (e.key === "ArrowUp" || e.key === "ArrowLeft") go(-1);
      if (e.key === " ") {
        e.preventDefault();
        togglePlay();
      }
    };
    document.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [go, onClose]);

  function togglePlay() {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) void v.play().catch(() => undefined);
    else v.pause();
  }

  async function toggleLike() {
    if (!viewerId) return needSignIn();
    const supabase = createClient();
    const next = !liked;
    setLiked(next);
    setLikes((n) => n + (next ? 1 : -1));
    const { error } = next
      ? await supabase.from("story_likes").insert({ video_id: story.id, user_id: viewerId })
      : await supabase.from("story_likes").delete().eq("video_id", story.id).eq("user_id", viewerId);
    if (error && !/duplicate/i.test(error.message)) {
      setLiked(!next);
      setLikes((n) => n + (next ? -1 : 1));
      setToast("Couldn't update your like. Try again.");
    }
  }

  async function share() {
    const url = `${window.location.origin}/shop/${story.seller.username}?story=${story.id}`;
    try {
      if (navigator.share) await navigator.share({ title: story.title, text: `${story.title} on Purple Vendra`, url });
      else {
        await navigator.clipboard.writeText(url);
        setToast("Link copied");
      }
      trackStory(story.id, "share", { campaignId: story.campaignId });
    } catch {
      /* share sheet closed */
    }
  }

  async function onFollow() {
    if (!viewerId) return needSignIn();
    if (!follow) return;
    const next = !follow.following;
    const r = await toggleFollow(story.seller.id, next);
    if (r.ok) setFollow({ following: next, followers: follow.followers + (next ? 1 : -1) });
    else if (r.error) setToast(r.error);
  }

  const isOwn = viewerId === story.seller.id;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/95" role="dialog" aria-modal="true" aria-label={story.title}>
      <button onClick={onClose} aria-label="Close" className="absolute right-3 top-3 z-20 h-10 w-10 rounded-full bg-white/15 text-xl text-white hover:bg-white/25">✕</button>
      {index > 0 && (
        <button onClick={() => go(-1)} aria-label="Previous story"
          className="absolute left-3 top-1/2 z-20 hidden h-11 w-11 -translate-y-1/2 rounded-full bg-white/15 text-white hover:bg-white/25 md:block">↑</button>
      )}
      {index < stories.length - 1 && (
        <button onClick={() => go(1)} aria-label="Next story"
          className="absolute right-3 top-1/2 z-20 hidden h-11 w-11 -translate-y-1/2 rounded-full bg-white/15 text-white hover:bg-white/25 md:block">↓</button>
      )}

      <div
        className="relative h-full w-full max-w-[min(100vw,calc(100dvh*9/16))] overflow-hidden bg-black md:h-[94dvh] md:rounded-3xl"
        onTouchStart={(e) => (touchY.current = e.touches[0].clientY)}
        onTouchEnd={(e) => {
          if (touchY.current === null || panel !== "none") return;
          const dy = e.changedTouches[0].clientY - touchY.current;
          if (Math.abs(dy) > 70) go(dy < 0 ? 1 : -1);
          touchY.current = null;
        }}
      >
        <video
          key={story.id}
          ref={videoRef}
          src={story.videoUrl}
          poster={story.posterUrl ?? undefined}
          autoPlay
          playsInline
          loop
          muted={muted}
          preload="auto"
          onClick={togglePlay}
          onLoadedMetadata={(e) => setNoPicture(e.currentTarget.videoWidth === 0)}
          onError={() => setNoPicture(true)}
          onPlay={() => setPlaying(true)}
          onPause={() => setPlaying(false)}
          onPlaying={() => trackStory(story.id, "view", { campaignId: story.campaignId })}
          onVolumeChange={(e) => setMuted(e.currentTarget.muted)}
          className="h-full w-full object-contain"
        />
        {noPicture && (
          <div className="absolute inset-x-6 top-1/3 rounded-2xl bg-black/70 p-4 text-center text-sm text-white">
            This video&apos;s format can&apos;t be shown on your device. Try another story, or visit the shop to see the products.
          </div>
        )}
        {!playing && !noPicture && (
          <button onClick={togglePlay} aria-label="Play"
            className="absolute left-1/2 top-1/2 flex h-16 w-16 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-black/50 text-3xl text-white">▶</button>
        )}
        <button onClick={() => setMuted((m) => !m)} aria-label={muted ? "Unmute" : "Mute"}
          className="absolute left-3 top-3 h-9 w-9 rounded-full bg-black/40 text-white">{muted ? "🔇" : "🔊"}</button>
        {story.campaignId && (
          <span className="absolute left-14 top-4 rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold uppercase text-brand-strong">Promoted</span>
        )}

        {/* Action column */}
        <div className="absolute bottom-40 right-2 flex flex-col items-center gap-4 text-white">
          <ActionButton label={likes.toLocaleString()} onClick={toggleLike} active={liked} icon={liked ? "♥" : "♡"} name="Like" />
          <ActionButton label={commentCount.toLocaleString()} onClick={() => setPanel("comments")} icon="💬" name="Comments" />
          <ActionButton label="Share" onClick={share} icon="↗" name="Share" />
          {story.products.length > 0 && (
            <ActionButton label="Shop" onClick={() => setPanel("products")} icon="🛍" name="Products in this video" />
          )}
          <ActionButton label="Report" onClick={() => (viewerId ? setPanel("report") : needSignIn())} icon="⚑" name="Report" small />
        </div>

        {/* Caption + seller + products */}
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/90 via-black/50 to-transparent p-4 pt-16 text-white">
          <div className="flex items-center gap-2">
            <Link href={`/shop/${story.seller.username}`} onClick={() => trackStory(story.id, "shop_visit", { campaignId: story.campaignId })}
              className="truncate font-semibold hover:underline">
              {story.seller.name} {story.seller.verified && <span className="text-green-300">✓</span>}
            </Link>
            {!isOwn && follow && (
              <button onClick={onFollow}
                className={`rounded-full px-3 py-0.5 text-xs font-semibold ${follow.following ? "border border-white/40" : "bg-accent text-brand-strong"}`}>
                {follow.following ? "Following" : "Follow"}
              </button>
            )}
          </div>
          <p className="mt-1 text-sm font-medium">{story.title}</p>
          {story.description && <p className="mt-0.5 line-clamp-2 text-xs text-white/80">{story.description}</p>}
          {story.products.length > 0 && (
            <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
              {story.products.map((p) => (
                <button key={p.id} onClick={() => setPanel("products")}
                  className="flex shrink-0 items-center gap-2 rounded-xl bg-white/95 p-1.5 pr-3 text-left text-brand-strong">
                  {p.image ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.image} alt="" className="h-9 w-9 rounded-lg object-cover" />
                  ) : (
                    <span className="h-9 w-9 rounded-lg bg-brand-soft" />
                  )}
                  <span className="max-w-32">
                    <span className="block truncate text-xs font-medium">{p.title}</span>
                    <span className="text-xs">{formatNaira(p.priceKobo)}</span>
                  </span>
                </button>
              ))}
            </div>
          )}
          <Link href={`/shop/${story.seller.username}`} onClick={() => trackStory(story.id, "shop_visit", { campaignId: story.campaignId })}
            className="mt-3 block rounded-xl bg-white/15 py-2 text-center text-sm font-medium hover:bg-white/25">
            Visit shop
          </Link>
        </div>

        {panel === "products" && (
          <Sheet title="Shop this video" onClose={() => setPanel("none")}>
            <ul className="space-y-3">
              {story.products.map((p) => (
                <ProductRow key={p.id} product={p} story={story} isOwn={isOwn} onSignIn={needSignIn} />
              ))}
            </ul>
          </Sheet>
        )}
        {panel === "comments" && (
          <Sheet title={`${commentCount} comments`} onClose={() => setPanel("none")}>
            <Comments story={story} viewerId={viewerId} onSignIn={needSignIn} onCount={setCommentCount} />
          </Sheet>
        )}
        {panel === "report" && (
          <Sheet title="Report this video" onClose={() => setPanel("none")}>
            {isOwn ? <p className="text-sm text-muted">This is your own video.</p> : <ReportButton videoId={story.id} startOpen />}
          </Sheet>
        )}

        {toast && (
          <button onClick={() => setToast(undefined)}
            className="absolute left-1/2 top-16 -translate-x-1/2 rounded-full bg-white px-4 py-1.5 text-sm text-brand-strong shadow">
            {toast}
          </button>
        )}
      </div>
    </div>
  );
}

function ActionButton({ icon, label, name, onClick, active, small }: {
  icon: string; label: string; name: string; onClick: () => void; active?: boolean; small?: boolean;
}) {
  return (
    <button onClick={onClick} aria-label={name} className="flex flex-col items-center gap-0.5">
      <span className={`flex items-center justify-center rounded-full bg-black/35 ${small ? "h-9 w-9 text-base" : "h-11 w-11 text-xl"} ${active ? "text-pink-400" : ""}`}>
        {icon}
      </span>
      <span className="text-[11px] drop-shadow">{label}</span>
    </button>
  );
}

function Sheet({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="absolute inset-0 z-10 flex flex-col justify-end bg-black/40" onClick={onClose}>
      <div className="max-h-[70%] overflow-y-auto rounded-t-3xl bg-white p-4 text-foreground" onClick={(e) => e.stopPropagation()}>
        <div className="mb-3 flex items-center justify-between">
          <h3 className="font-semibold text-brand-strong">{title}</h3>
          <button onClick={onClose} aria-label="Close" className="text-muted">✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function ProductRow({ product, story, isOwn, onSignIn }: {
  product: StoryItem["products"][number]; story: StoryItem; isOwn: boolean; onSignIn: () => void;
}) {
  const [state, setState] = useState<"idle" | "added" | string>("idle");
  const [pending, start] = useTransition();
  return (
    <li className="flex items-center gap-3">
      <Link href={`/l/${product.id}`} onClick={() => trackStory(story.id, "product_click", { listingId: product.id, campaignId: story.campaignId })}
        className="flex min-w-0 flex-1 items-center gap-3">
        {product.image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={product.image} alt="" className="h-14 w-14 rounded-xl object-cover" />
        ) : (
          <span className="h-14 w-14 rounded-xl bg-brand-soft" />
        )}
        <span className="min-w-0">
          <span className="block truncate font-medium hover:text-brand">{product.title}</span>
          <span className="text-sm">
            {product.priceIsStarting && "From "}
            {formatNaira(product.priceKobo)}
          </span>
        </span>
      </Link>
      {!isOwn &&
        (state === "added" ? (
          <Link href="/cart" className="rounded-xl bg-green-600 px-3 py-2 text-xs font-medium text-white">✓ View cart</Link>
        ) : (
          <button disabled={pending}
            onClick={() =>
              start(async () => {
                const r = await addStoryProductToCart(story.id, product.id, story.campaignId);
                if (r.signIn) return onSignIn();
                setState(r.error ?? "added");
              })
            }
            className="rounded-xl bg-brand px-3 py-2 text-xs font-medium text-white hover:bg-brand-strong disabled:opacity-60">
            {pending ? "Adding…" : "Add to cart"}
          </button>
        ))}
      {state !== "idle" && state !== "added" && <p className="w-full text-xs text-red-700">{state}</p>}
    </li>
  );
}

function Comments({ story, viewerId, onSignIn, onCount }: {
  story: StoryItem; viewerId: string | null; onSignIn: () => void; onCount: (fn: (n: number) => number) => void;
}) {
  const [comments, setComments] = useState<Comment[] | null>(null);
  const [body, setBody] = useState("");
  const [error, setError] = useState<string>();
  const [sending, setSending] = useState(false);

  const fetchComments = useCallback(
    () =>
      createClient()
        .rpc("get_story_comments", { p_video: story.id, p_limit: 100 })
        .then(({ data }) => setComments((data ?? []) as Comment[])),
    [story.id],
  );
  useEffect(() => {
    void createClient()
      .rpc("get_story_comments", { p_video: story.id, p_limit: 100 })
      .then(({ data }) => setComments((data ?? []) as Comment[]));
  }, [story.id]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    if (!viewerId) return onSignIn();
    const text = body.trim();
    if (!text) return;
    setSending(true);
    setError(undefined);
    const { error } = await createClient().from("story_comments").insert({ video_id: story.id, user_id: viewerId, body: text });
    setSending(false);
    if (error) return setError(/fast/.test(error.message) ? error.message : "Couldn't post your comment.");
    setBody("");
    onCount((n) => n + 1);
    void fetchComments();
  }

  async function remove(id: string) {
    const { error } = await createClient().from("story_comments").delete().eq("id", id);
    if (error) return setError("Couldn't delete that comment.");
    onCount((n) => Math.max(0, n - 1));
    setComments((c) => c?.filter((x) => x.id !== id) ?? null);
  }

  return (
    <div className="space-y-3">
      <form onSubmit={send} className="flex gap-2">
        <input value={body} onChange={(e) => setBody(e.target.value)} maxLength={500}
          placeholder={viewerId ? "Add a comment…" : "Sign in to comment"} onFocus={() => !viewerId && onSignIn()}
          className="min-w-0 flex-1 rounded-full border border-border px-4 py-2 text-sm outline-none focus:border-brand" />
        <button disabled={sending || !body.trim()} className="rounded-full bg-brand px-4 text-sm font-medium text-white disabled:opacity-50">Post</button>
      </form>
      {error && <p className="text-xs text-red-700">{error}</p>}
      <p className="text-[11px] text-muted">Keep it kind. Never share phone numbers or pay outside Purple Vendra.</p>
      {comments === null ? (
        <p className="text-sm text-muted">Loading…</p>
      ) : comments.length === 0 ? (
        <p className="text-sm text-muted">No comments yet. Be the first.</p>
      ) : (
        <ul className="space-y-3">
          {comments.map((c) => (
            <li key={c.id} className="text-sm">
              <span className="font-medium text-brand-strong">
                {c.display_name}
                {c.is_seller && <span className="ml-1 rounded bg-brand-soft px-1 text-[10px] text-brand">Seller</span>}
              </span>
              <span className="ml-2 text-xs text-muted">{new Date(c.created_at).toLocaleDateString("en-NG", { day: "numeric", month: "short" })}</span>
              <p className="whitespace-pre-line">{c.body}</p>
              {(c.user_id === viewerId || story.seller.id === viewerId) && (
                <button onClick={() => remove(c.id)} className="text-xs text-muted hover:text-red-600">Delete</button>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
