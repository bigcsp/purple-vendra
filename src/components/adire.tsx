/**
 * Adire-inspired marks: resist-dye circles with tied "stitch" dots,
 * the visual signature of Purple Shop. Pure SVG, no images.
 */
export function LogoMark({ className = "h-8 w-8" }: { className?: string }) {
  return (
    <svg viewBox="0 0 40 40" className={className} aria-hidden>
      <rect width="40" height="40" rx="11" fill="#6d28d9" />
      <circle cx="20" cy="20" r="11.5" fill="none" stroke="#efe6ff" strokeWidth="2.2" />
      <circle cx="20" cy="20" r="6.5" fill="none" stroke="#e8a317" strokeWidth="2.2" />
      <circle cx="20" cy="20" r="2.2" fill="#efe6ff" />
      {Array.from({ length: 8 }).map((_, i) => {
        const a = (i * Math.PI) / 4;
        return <circle key={i} cx={20 + Math.cos(a) * 15.5} cy={20 + Math.sin(a) * 15.5} r="1.1" fill="#efe6ff" opacity="0.8" />;
      })}
    </svg>
  );
}

/** Large decorative adire field for the homepage banner. */
export function AdireField({ className = "" }: { className?: string }) {
  const motifs = [
    { x: 70, y: 70, r: 58 },
    { x: 215, y: 60, r: 44 },
    { x: 330, y: 120, r: 62 },
    { x: 120, y: 205, r: 46 },
    { x: 255, y: 225, r: 56 },
    { x: 60, y: 330, r: 52 },
    { x: 190, y: 345, r: 40 },
    { x: 320, y: 330, r: 50 },
  ];
  return (
    <svg viewBox="0 0 400 400" className={className} aria-hidden preserveAspectRatio="xMidYMid slice">
      {/* stitch lines, like thread tied before dyeing */}
      {[40, 140, 270, 380].map((y) => (
        <line key={y} x1="0" x2="400" y1={y} y2={y} stroke="#efe6ff" strokeOpacity="0.14" strokeWidth="2" strokeDasharray="2 9" />
      ))}
      {motifs.map((m, i) => (
        <g key={i}>
          <circle cx={m.x} cy={m.y} r={m.r} fill="none" stroke="#efe6ff" strokeOpacity="0.18" strokeWidth="2" />
          <circle cx={m.x} cy={m.y} r={m.r * 0.66} fill="none" stroke={i % 3 === 0 ? "#e8a317" : "#c4b5fd"} strokeOpacity={i % 3 === 0 ? 0.7 : 0.35} strokeWidth="3" />
          <circle cx={m.x} cy={m.y} r={m.r * 0.33} fill="#efe6ff" fillOpacity="0.12" />
          {Array.from({ length: 12 }).map((_, j) => {
            const a = (j * Math.PI) / 6;
            return <circle key={j} cx={m.x + Math.cos(a) * m.r * 0.85} cy={m.y + Math.sin(a) * m.r * 0.85} r="2" fill="#efe6ff" fillOpacity="0.35" />;
          })}
        </g>
      ))}
    </svg>
  );
}
