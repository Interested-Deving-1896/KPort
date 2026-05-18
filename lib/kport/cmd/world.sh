#!/usr/bin/env bash
# kport world
#
# Lists all installed packages with their versions and categories.
#
# Usage: kport world [--category <cat>] [--short]
#
# Options:
#   --category <cat>   Filter by category
#   --short            Print only package names (one per line)

set -uo pipefail

FILTER_CATEGORY=""
SHORT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category) FILTER_CATEGORY="$2"; shift 2 ;;
    --short)    SHORT=true; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) kport_die "Unknown option: $1" ;;
  esac
done

if [[ ! -d "$KPORT_DB_INSTALLED" ]]; then
  kport_warn "No packages installed."
  exit 0
fi

count=0
while IFS= read -r pkgname; do
  [[ -z "$pkgname" ]] && continue
  version=$(kport_db_read "$pkgname" version 2>/dev/null || echo "?")
  category=$(kport_db_read "$pkgname" category 2>/dev/null || echo "?")

  [[ -n "$FILTER_CATEGORY" && "$category" != *"$FILTER_CATEGORY"* ]] && continue

  if [[ "$SHORT" == "true" ]]; then
    echo "$pkgname"
  else
    printf "  %-40s %-12s %s\n" "$pkgname" "$version" "$category"
  fi
  count=$(( count + 1 ))
done < <(ls "$KPORT_DB_INSTALLED" 2>/dev/null | sort)

if [[ "$count" -eq 0 ]]; then
  kport_warn "No packages installed${FILTER_CATEGORY:+ in category '${FILTER_CATEGORY}'}."
  exit 0
fi

[[ "$SHORT" != "true" ]] && echo -e "\n${C_DIM}${count} package(s) installed${C_RESET}"
