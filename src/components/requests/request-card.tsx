import Link from "next/link";
import { formatNaira } from "@/lib/money";
import { postedAgo, timeLeft, type BoardRequest } from "@/server/queries/requests";

/** One request on the board. The buyer is never named here. */
export function RequestCard({ r, categoryName }: { r: BoardRequest; categoryName?: string }) {
  const where = r.city ? `${r.city}, ${r.state}` : r.state;
  return (
    <li>
      <Link
        href={`/requests/${r.id}`}
        className={`flex h-full flex-col rounded-3xl border bg-card p-5 transition hover:border-brand ${r.is_full ? "border-border opacity-75" : "border-border"}`}
      >
        <div className="flex items-start justify-between gap-3">
          <h3 className="font-semibold leading-snug text-brand-strong">{r.title}</h3>
          <span className="shrink-0 rounded-full bg-brand-soft px-2.5 py-0.5 text-sm font-semibold text-brand-strong">
            {r.budget_kobo ? formatNaira(r.budget_kobo) : "Open budget"}
          </span>
        </div>
        <p className="mt-2 line-clamp-3 text-sm text-foreground/85">{r.description}</p>
        <div className="mt-auto pt-4 text-xs text-muted">
          <p>
            A buyer in {where}
            {categoryName && <> · {categoryName}</>}
          </p>
          <p className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1">
            <span>{postedAgo(r.created_at)}</span>
            {r.deadline && (
              <span>
                Needed by{" "}
                {new Date(r.deadline).toLocaleDateString("en-NG", { day: "numeric", month: "short", timeZone: "Africa/Lagos" })}
              </span>
            )}
            <span>{timeLeft(r.expires_at)}</span>
            <span className={`font-medium ${r.is_full ? "text-muted" : "text-brand"}`}>
              {r.is_full ? "Full (10 offers)" : `${r.offer_count} offer${r.offer_count === 1 ? "" : "s"}`}
            </span>
            {r.you_offered && <span className="rounded-full bg-green-50 px-2 py-0.5 font-medium text-green-800">You offered</span>}
          </p>
        </div>
      </Link>
    </li>
  );
}
