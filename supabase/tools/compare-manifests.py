#!/usr/bin/env python3
"""Compare two schema manifests produced by supabase/tools/schema-manifest.sql.

Usage: python3 supabase/tools/compare-manifests.py <expected.tsv> <actual.tsv> [--allow allowed.tsv]

Prints objects only in one side and objects whose fingerprint differs. For tables it
names which part differs (columns, constraints, indexes, triggers, rls, grants).
Rows listed in --allow (kind<TAB>ident<TAB>reason) are reported as "allowed".
Exit code 0 = no unexplained differences, 1 = differences found.
"""
import sys

TABLE_PARTS = ["columns", "constraints", "indexes", "triggers", "rls", "grants"]


def load(path):
    rows = {}
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        kind, ident, fp = line.split("\t")
        rows[(kind, ident)] = fp
    return rows


def explain(kind, a, b):
    if kind == "table":
        pa, pb = a.split("."), b.split(".")
        return ", ".join(n for n, x, y in zip(TABLE_PARTS, pa, pb) if x != y)
    if kind == "function":
        da, ga = a.split("/")
        db, gb = b.split("/")
        parts = []
        if da != db:
            parts.append("definition")
        if ga != gb:
            parts.append("grants")
        return ", ".join(parts)
    return "definition"


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    expected, actual = load(argv[1]), load(argv[2])
    allowed = {}
    if "--allow" in argv:
        for line in open(argv[argv.index("--allow") + 1], encoding="utf-8"):
            if line.strip() and not line.startswith("#"):
                k, i, reason = line.rstrip("\n").split("\t", 2)
                allowed[(k, i)] = reason
    unexplained = 0
    report = []
    for key in sorted(set(expected) | set(actual)):
        a, b = expected.get(key), actual.get(key)
        if a == b:
            continue
        if a is None:
            what = "only in ACTUAL"
        elif b is None:
            what = "only in EXPECTED"
        else:
            what = "differs: " + explain(key[0], a, b)
        if key in allowed:
            report.append(f"ALLOWED  {key[0]:<18} {key[1]}  ({what}; {allowed[key]})")
        else:
            unexplained += 1
            report.append(f"DIFF     {key[0]:<18} {key[1]}  ({what})")
    same = len(set(expected) & set(actual)) - sum(1 for k in set(expected) & set(actual) if expected[k] != actual[k])
    print(f"expected={len(expected)} actual={len(actual)} identical={same} unexplained={unexplained} allowed={len(report) - unexplained}")
    print("\n".join(report))
    return 1 if unexplained else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
