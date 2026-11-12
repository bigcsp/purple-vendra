import type { MetadataRoute } from "next";

/** Makes Purple Shop installable as an app (Add to Home Screen). */
export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    name: "Purple Shop",
    short_name: "Purple Shop",
    description: "Nigerian makers, freelancers and pros in one place, with safe escrow payments.",
    start_url: "/?source=app",
    scope: "/",
    display: "standalone",
    orientation: "portrait",
    background_color: "#fbf8ff",
    theme_color: "#6d28d9",
    lang: "en-NG",
    categories: ["shopping", "lifestyle", "business"],
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/maskable-192.png", sizes: "192x192", type: "image/png", purpose: "maskable" },
      { src: "/icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
    shortcuts: [
      { name: "Search", url: "/search", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
      { name: "Messages", url: "/messages", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
      { name: "Saved", url: "/saved", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
      { name: "Seller hub", url: "/sell", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
    ],
  };
}
