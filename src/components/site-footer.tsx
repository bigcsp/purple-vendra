import Link from "next/link";
import { LogoMark } from "./adire";

export function SiteFooter() {
  return (
    <footer className="mt-16 border-t border-border">
      <div className="mx-auto grid w-full max-w-5xl gap-8 px-5 py-10 text-sm sm:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          <Link href="/" className="flex items-center gap-2 font-display text-lg font-bold text-brand-strong">
            <LogoMark className="h-7 w-7" /> Purple Vendra
          </Link>
          <p className="mt-2 max-w-xs text-muted">
            Nigerian makers, freelancers and pros in one place. Pay safely: your money is held until you receive what
            you paid for.
          </p>
        </div>
        <nav aria-label="Shop">
          <p className="font-semibold text-brand-strong">Shop</p>
          <ul className="mt-2 space-y-1.5 text-muted">
            <li><Link href="/stories" className="hover:text-brand">Vendra Stories</Link></li>
            <li><Link href="/search?sort=newest" className="hover:text-brand">New this week</Link></li>
            <li><Link href="/c/fashion-adire" className="hover:text-brand">Fashion & Adire</Link></li>
            <li><Link href="/c/home-services" className="hover:text-brand">Home services</Link></li>
          </ul>
        </nav>
        <nav aria-label="Sell and account">
          <p className="font-semibold text-brand-strong">Sell & account</p>
          <ul className="mt-2 space-y-1.5 text-muted">
            <li><Link href="/signup?intent=sell" className="hover:text-brand">Open a shop</Link></li>
            <li><Link href="/account" className="hover:text-brand">Your account</Link></li>
            <li><Link href="/privacy" className="hover:text-brand">Privacy policy</Link></li>
          </ul>
        </nav>
      </div>
      <p className="pb-6 text-center text-xs text-muted">© {2026} Purple Vendra. Made in Lagos.</p>
    </footer>
  );
}
