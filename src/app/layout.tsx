import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import localFont from "next/font/local";
import { SiteFooter } from "@/components/site-footer";
import { themeScript } from "@/lib/theme-script";
import { Suspense } from "react";
import { MobileNavWithCounts } from "@/components/mobile-nav-server";
import "./globals.css";

/** Display face for headings (self-hosted from @fontsource, no Google request). */
const bricolage = localFont({
  src: "../../node_modules/@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2",
  variable: "--font-bricolage",
  weight: "200 800",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Purple Shop — Discover. Create. Promote. Sell.",
  description:
    "Nigeria's creative marketplace: fashion, art, design, photo & video talent, and tech freelancers, with safe escrow checkout.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${GeistSans.variable} ${GeistMono.variable} ${bricolage.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        <meta name="theme-color" content="#6d28d9" />
      </head>
      <body className="min-h-full flex flex-col pb-16 sm:pb-0">
        {children}
        <SiteFooter />
        <Suspense fallback={null}>
          <MobileNavWithCounts />
        </Suspense>
      </body>
    </html>
  );
}
