/** Same size as the sidebar, shown for the moment before it loads (no layout jump). */
export function SidebarSkeleton() {
  return (
    <div aria-hidden className="ps-sidebar fixed inset-y-0 left-0 z-40 hidden flex-col border-r border-border bg-card md:flex">
      <div className="h-16" />
      <div className="space-y-2 px-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-9 rounded-lg bg-brand-soft/40" />
        ))}
      </div>
    </div>
  );
}
