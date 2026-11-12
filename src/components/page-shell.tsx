import type { ReactNode } from "react";
import { SiteHeader } from "./site-header";

/** Page wrapper used by the sign-in, account and seller pages. */
export function PageShell({ children, narrow = false, wide = false }: { children: ReactNode; narrow?: boolean; wide?: boolean }) {
  return (
    <main className="mx-auto w-full max-w-5xl flex-1 px-5 py-8">
      <SiteHeader />
      <div className={`mx-auto mt-10 ${narrow ? "max-w-md" : wide ? "max-w-5xl" : "max-w-2xl"}`}>{children}</div>
    </main>
  );
}
