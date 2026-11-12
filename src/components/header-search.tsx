"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { SearchBox } from "./search-box";

/** Header search that keeps your words in the box on the results page. */
export function HeaderSearch() {
  const path = usePathname();
  const params = useSearchParams();
  const q = path === "/search" ? params.get("q") ?? "" : "";
  return <SearchBox key={q} defaultValue={q} />;
}
