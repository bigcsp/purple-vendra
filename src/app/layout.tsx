import type { Metadata, Viewport } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import localFont from "next/font/local";
import { SiteFooter } from "@/components/site-footer";
import { themeScript } from "@/lib/theme-script";
import { Suspense } from "react";
import { MobileNavWithCounts, SidebarWithData } from "@/components/mobile-nav-server";
import { SidebarSkeleton } from "@/components/nav/sidebar-skeleton";
import { InstallAppBanner, RegisterServiceWorker } from "@/components/install-app";
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
  applicationName: "Purple Shop",
  appleWebApp: { capable: true, title: "Purple Shop", statusBarStyle: "default" },
  formatDetection: { telephone: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#6d28d9" },
    { media: "(prefers-color-scheme: dark)", color: "#120b1c" },
  ],
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
      </head>
      <body className="min-h-full pb-[calc(4rem+env(safe-area-inset-bottom))] md:pb-0">
        <Suspense fallback={<SidebarSkeleton />}>
          <SidebarWithData />
        </Suspense>
        <div className="app-main flex min-h-dvh flex-col">
          {children}
          <SiteFooter />
        </div>
        <Suspense fallback={null}>
          <MobileNavWithCounts />
        </Suspense>
        <RegisterServiceWorker />
        <InstallAppBanner />
      </body>
    </html>
  );
}
