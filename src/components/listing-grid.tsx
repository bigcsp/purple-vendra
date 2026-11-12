import Link from "next/link";
import { formatNaira } from "@/lib/money";
import { publicFileUrl } from "@/lib/storage-url";
import { SaveHeart } from "./save-button";

export type GridListing = {
  id: string;
  title: string;
  price_kobo: number;
  price_is_starting: boolean;
  quote_on_request?: boolean;
  image_path: string | null;
  seller?: { username: string; name: string; verified: boolean } | null;
  place?: string | null;
  featured?: boolean;
};

/** Listing cards used on search, category and shop pages. */
export function ListingGrid({ listings, saveable = true }: { listings: GridListing[]; saveable?: boolean }) {
  return (
    <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
      {listings.map((l) => {
        const img = publicFileUrl("listing-images", l.image_path);
        return (
          <li key={l.id} className="relative">
            {saveable && <SaveHeart listingId={l.id} title={l.title} />}
            <Link href={`/l/${l.id}`} className="block h-full overflow-hidden rounded-2xl border border-border bg-card transition hover:border-brand">
              <div className="relative">
                {img ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={img} alt="" loading="lazy" className="aspect-square w-full object-cover" />
                ) : (
                  <div className="aspect-square bg-brand-soft" />
                )}
                {l.featured && (
                  <span className="absolute left-2 top-2 rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold text-brand-strong">
                    Featured
                  </span>
                )}
              </div>
              <div className="p-3">
                <p className="line-clamp-2 text-sm font-medium">{l.title}</p>
                <p className="mt-0.5 text-sm text-brand-strong">
                  {l.quote_on_request ? (
                    <span className="text-muted">Quote on request</span>
                  ) : (
                    <>
                      {l.price_is_starting && <span className="text-muted">From </span>}
                      {formatNaira(l.price_kobo)}
                    </>
                  )}
                </p>
                {l.seller && (
                  <p className="mt-1 truncate text-xs text-muted">
                    {l.seller.name} {l.seller.verified && <span className="text-green-700">✓</span>}
                    {l.place ? ` · ${l.place}` : ""}
                  </p>
                )}
              </div>
            </Link>
          </li>
        );
      })}
    </ul>
  );
}
