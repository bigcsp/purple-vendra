/**
 * The Purple Shop wordmark: bold "purple" in an outlined frame, light
 * "shop" on a solid fill. Colours follow the theme (brand purple in light
 * mode, lighter purple in dark mode). `tone="light"` is for purple or dark
 * backgrounds, where the frame and fill turn white.
 */
export function Wordmark({
  size = "md",
  tone = "brand",
  className = "",
}: {
  size?: "sm" | "md" | "lg";
  tone?: "brand" | "light";
  className?: string;
}) {
  const text = { sm: "text-base", md: "text-lg sm:text-xl", lg: "text-3xl sm:text-4xl" }[size];
  const frame = tone === "light" ? "border-white" : "border-brand";
  const left = tone === "light" ? "text-white" : "text-brand";
  const right = tone === "light" ? "bg-white text-brand" : "bg-brand text-white";

  return (
    <span
      className={`inline-flex items-stretch overflow-hidden rounded-[0.32em] border-[0.09em] font-display leading-none ${frame} ${text} ${className}`}
    >
      <span className={`px-[0.22em] pb-[0.2em] pt-[0.12em] font-extrabold tracking-[-0.035em] ${left}`} aria-hidden>purple</span>
      <span className={`pb-[0.2em] pl-[0.18em] pr-[0.26em] pt-[0.12em] font-light tracking-[-0.01em] ${right}`} aria-hidden>shop</span>
      <span className="sr-only">Purple Shop</span>
    </span>
  );
}
