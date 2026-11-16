#!/usr/bin/env python3
"""
Purple Shop: video storage & bandwidth cost model (v1.2, 16 Nov 2026)

Reproducible: no randomness, no network. Run:  python3 docs/cost-model.py
Change any value in ASSUMPTIONS or PRICING and re-run.

The two inputs are kept apart on purpose:
  PRICING     = verified provider prices (source + date checked)   -> [Verified]
  ASSUMPTIONS = my estimates about Purple Shop usage               -> [Assumption]
  MEASURED    = taken from the live database                       -> [Measured]
"""

# ---------------------------------------------------------------- MEASURED
# Live story video, 16 Nov 2026: 12.63 MB, 31.0 s, 720x1280,
# browser encode = libx264 CRF 26 veryfast, AAC 128 kbps, no bitrate cap.
MEASURED_MB = 12.63
MEASURED_SECONDS = 31.0

# ---------------------------------------------------------------- PRICING [Verified]
# Source: https://supabase.com/pricing (checked 16 Nov 2026)
PRICING = {
    "pro_base_usd_per_month": 25.00,      # includes $10 compute credit = one Micro instance
    "pro_storage_included_gb": 100,
    "pro_storage_usd_per_gb": 0.0213,     # per GB-month over the included amount
    "pro_egress_included_gb": 250,        # uncached egress
    "pro_egress_usd_per_gb": 0.09,
    "pro_cached_egress_included_gb": 250,
    "pro_cached_egress_usd_per_gb": 0.03,
    "free_storage_gb": 1,
    "free_egress_gb": 5,
    "free_cached_egress_gb": 5,
}

# ---------------------------------------------------------------- ASSUMPTIONS [Assumption]
ASSUMPTIONS = {
    "avg_clip_seconds": 35,        # typical clip; maximum allowed is 60
    "max_clip_seconds": 60,
    "thumb_mb": 0.08,              # measured cover size, rounded
    "capped_video_mbps": 1.8,      # proposed x264 maxrate
    "audio_mbps": 0.128,
    "watch_fraction": 0.60,        # share of each file actually delivered per view
    "cached_share": 0.50,          # share of delivered bytes served from CDN cache
    "storage_uses_month_end": True,  # bill storage on library size at end of month (conservative)
}
SCENARIOS = {
    # sellers_m6 / sellers_m12: active video sellers; linear growth 0 -> m6 -> m12
    # uploads: videos per active seller per month
    # first_month_views: views a video gets in the month it is uploaded
    # tail_views: views per month for each older video
    "Low":  {"sellers_m6": 50,  "sellers_m12": 150,  "uploads": 1.5, "first_month_views": 60,  "tail_views": 5},
    "Mid":  {"sellers_m6": 200, "sellers_m12": 600,  "uploads": 2.0, "first_month_views": 150, "tail_views": 10},
    "High": {"sellers_m6": 500, "sellers_m12": 1500, "uploads": 2.5, "first_month_views": 400, "tail_views": 25},
}

# ---------------------------------------------------------------- FORMULAS
def mb_per_second(capped: bool) -> float:
    """Measured rate (uncapped) or bitrate cap (Mbps -> MB/s = /8)."""
    if not capped:
        return MEASURED_MB / MEASURED_SECONDS                                   # 0.4074 MB/s
    return (ASSUMPTIONS["capped_video_mbps"] + ASSUMPTIONS["audio_mbps"]) / 8   # 0.2410 MB/s

def active_sellers(month: int, s: dict) -> float:
    """Linear 0 -> sellers_m6 over months 1-6, then sellers_m6 -> sellers_m12 over months 7-12."""
    if month <= 6:
        return s["sellers_m6"] * month / 6
    return s["sellers_m6"] + (s["sellers_m12"] - s["sellers_m6"]) * (month - 6) / 6

def project(scenario: dict, capped: bool):
    """Returns one row per month 1..12.
       new_videos(m)  = active_sellers(m) * uploads
       library(m)     = library(m-1) + new_videos(m)                 (no deletions assumed)
       file_mb        = avg_clip_seconds * MB/s + thumb_mb
       storage_gb(m)  = library(m) * file_mb / 1024
       views(m)       = new_videos(m) * first_month_views + library(m-1) * tail_views
       delivered_gb   = views(m) * avg_clip_seconds * MB/s * watch_fraction / 1024
       cached_gb      = delivered_gb * cached_share
       uncached_gb    = delivered_gb * (1 - cached_share)
       pro_bill(m)    = base
                      + max(0, storage_gb - 100) * 0.0213
                      + max(0, uncached_gb - 250) * 0.09
                      + max(0, cached_gb  - 250) * 0.03
    """
    rate = mb_per_second(capped)
    a, p = ASSUMPTIONS, PRICING
    file_mb = a["avg_clip_seconds"] * rate + a["thumb_mb"]
    library_prev = 0.0
    rows = []
    for m in range(1, 13):
        new = active_sellers(m, scenario) * scenario["uploads"]
        views = new * scenario["first_month_views"] + library_prev * scenario["tail_views"]
        delivered = views * a["avg_clip_seconds"] * rate * a["watch_fraction"] / 1024
        cached = delivered * a["cached_share"]
        uncached = delivered - cached
        library = library_prev + new
        storage = library * file_mb / 1024
        bill = (p["pro_base_usd_per_month"]
                + max(0, storage - p["pro_storage_included_gb"]) * p["pro_storage_usd_per_gb"]
                + max(0, uncached - p["pro_egress_included_gb"]) * p["pro_egress_usd_per_gb"]
                + max(0, cached - p["pro_cached_egress_included_gb"]) * p["pro_cached_egress_usd_per_gb"])
        over_free = (storage > p["free_storage_gb"] or uncached > p["free_egress_gb"]
                     or cached > p["free_cached_egress_gb"])
        rows.append(dict(month=m, sellers=active_sellers(m, scenario), videos=library, storage_gb=storage,
                         uncached_gb=uncached, cached_gb=cached, bill=bill, over_free=over_free))
        library_prev = library
    return rows

def main():
    for capped in (True, False):
        rate = mb_per_second(capped)
        label = "PROPOSED (1.8 Mbps cap)" if capped else "CURRENT (uncapped, measured)"
        print(f"\n## {label}: {rate:.4f} MB/s -> avg {ASSUMPTIONS['avg_clip_seconds']} s clip "
              f"{ASSUMPTIONS['avg_clip_seconds']*rate:.1f} MB, max {ASSUMPTIONS['max_clip_seconds']} s "
              f"{ASSUMPTIONS['max_clip_seconds']*rate:.1f} MB")
        print("| Scenario | Month | Sellers | Videos | Storage GB | Uncached egress GB | Cached egress GB | "
              "Pro bill $/mo | Over Free? | Total m1-6 $ | Total m1-12 $ |")
        print("|---|---|---|---|---|---|---|---|---|---|---|")
        for name, s in SCENARIOS.items():
            rows = project(s, capped)
            t6 = sum(r["bill"] for r in rows[:6]); t12 = sum(r["bill"] for r in rows)
            first_over = next((r["month"] for r in rows if r["over_free"]), None)
            for r in (rows[5], rows[11]):
                print(f"| {name} | {r['month']} | {r['sellers']:.0f} | {r['videos']:.0f} | {r['storage_gb']:.1f} | "
                      f"{r['uncached_gb']:.1f} | {r['cached_gb']:.1f} | {r['bill']:.2f} | "
                      f"{'yes' if r['over_free'] else 'no'} (from m{first_over}) | {t6:.0f} | {t12:.0f} |")
    print("\nTotals assume the Pro plan is active from month 1 of video go-live (12 x $25 = $300 minimum).")

if __name__ == "__main__":
    main()
