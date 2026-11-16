# Video storage/egress projection for Purple Shop
# Measured: 12.63 MB for 31.0 s at 720x1280, CRF 26 veryfast + 128k AAC -> 0.407 MB/s (~3.3 Mbps)
MBPS_NOW = 12.63/31.0
# Proposed cap: video maxrate 1.8 Mbps + 128 kbps audio ~= 1.93 Mbps -> 0.241 MB/s
MBPS_CAP = (1.8+0.128)/8
THUMB = 0.08
AVG_SEC = 35   # assumed average clip length (max 60)
scen = {  # active video sellers at month 6 / 12, videos per seller per month, views per video (1st month), tail views/month after
 "Low":  dict(s6=50,  s12=150,  vpm=1.5, v1=60,  tail=5),
 "Mid":  dict(s6=200, s12=600,  vpm=2.0, v1=150, tail=10),
 "High": dict(s6=500, s12=1500, vpm=2.5, v1=400, tail=25),
}
WATCH = 0.6     # average fraction of file delivered per view
CACHED = 0.5    # share of egress served from CDN cache (Pro Smart CDN)
def run(rate):
    out={}
    for n,p in scen.items():
        lib=0; stor=0; res={}
        for m in range(1,13):
            sellers = p["s6"]*m/6 if m<=6 else p["s6"]+(p["s12"]-p["s6"])*(m-6)/6
            new = sellers*p["vpm"]
            size = AVG_SEC*rate+THUMB
            views = new*p["v1"] + lib*p["tail"]
            egress_gb = views*AVG_SEC*rate*WATCH/1024
            lib += new; stor = lib*size/1024
            if m in (6,12):
                unc = egress_gb*(1-CACHED); cac = egress_gb*CACHED
                pro = 25 + max(0,stor-100)*0.0213 + max(0,unc-250)*0.09 + max(0,cac-250)*0.03
                res[m]=(round(sellers),round(lib),stor,egress_gb,pro)
        out[n]=res
    return out
for label,rate in (("current settings",MBPS_NOW),("bitrate-capped",MBPS_CAP)):
    print(f"\n== {label}: avg {AVG_SEC}s clip = {AVG_SEC*rate:.1f} MB, 60s max = {60*rate:.1f} MB ==")
    for n,res in run(rate).items():
        for m,(s,lib,st,eg,pro) in res.items():
            print(f"{n:4} M{m:2}: sellers {s:5} videos {lib:6} storage {st:7.1f} GB  egress/mo {eg:8.1f} GB  Pro est ${pro:7.2f}/mo")
