#!/usr/bin/env python3
"""
keyword-check.py  keywords_yml  pkgkey  channel

Reads keywords.yml and prints the accepted stability list for the given
package key (category/pkgname). Checks per-package overrides first, then
falls back to the global accept_keywords.stability list.

Exits 0 and prints space-separated stability keywords on success.
Exits 1 and prints "stable testing" on any parse error (safe fallback).
"""
import re, sys

if len(sys.argv) < 4:
    print("stable testing")
    sys.exit(1)

keywords_yml, pkg_key, channel = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    txt = open(keywords_yml).read()

    # Per-package override block
    pkg_match = re.search(
        r'-\s+pkg:\s+' + re.escape(pkg_key) + r'.*?stability:\s*\[([^\]]+)\]',
        txt, re.DOTALL
    )
    if pkg_match:
        print(pkg_match.group(1).replace(',', ' ').replace("'", '').replace('"', ''))
        sys.exit(0)

    # Global default
    m = re.search(r'accept_keywords:.*?stability:\s*\[([^\]]+)\]', txt, re.DOTALL)
    if m:
        print(m.group(1).replace(',', ' ').replace("'", '').replace('"', ''))
        sys.exit(0)
except Exception:
    pass

print("stable testing")
sys.exit(1)
