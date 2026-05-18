#!/usr/bin/env bash
# kport world
#
# Lists installed packages. Packages in the world set (explicitly installed)
# are shown separately from dep-only packages (pulled in as dependencies).
#
# Usage: kport world [options]
#
# Options:
#   --category <cat>   Filter by category (substring match)
#   --short            Print only package names, one per line
#   --deps-only        Show only dep-only packages (not in world set)
#   --world-only       Show only explicitly installed packages
#   --help

set -uo pipefail

FILTER_CATEGORY=""
SHORT=false
DEPS_ONLY=false
WORLD_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category)   FILTER_CATEGORY="$2"; shift 2 ;;
    --short)      SHORT=true;           shift ;;
    --deps-only)  DEPS_ONLY=true;       shift ;;
    --world-only) WORLD_ONLY=true;      shift ;;
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

# Build world-set lookup from the world file
declare -A in_world=()
if [[ -f "$KPORT_DB_WORLD" ]]; then
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    pkg="${entry##*/}"
    in_world["$pkg"]=1
  done < "$KPORT_DB_WORLD"
fi

# Collect all installed packages
declare -a world_pkgs=() dep_pkgs=()

while IFS= read -r pkgname; do
  [[ -z "$pkgname" ]] && continue
  version=$(kport_db_read "$pkgname" version 2>/dev/null || echo "?")
  category=$(kport_db_read "$pkgname" category 2>/dev/null || echo "?")
  [[ -n "$FILTER_CATEGORY" && "$category" != *"$FILTER_CATEGORY"* ]] && continue

  if [[ -n "${in_world[$pkgname]:-}" ]]; then
    world_pkgs+=("$pkgname|$version|$category")
  else
    dep_pkgs+=("$pkgname|$version|$category")
  fi
done < <(ls "$KPORT_DB_INSTALLED" 2>/dev/null | sort)

_print_pkg() {
  local entry="$1"
  local pkgname="${entry%%|*}"
  local rest="${entry#*|}"
  local version="${rest%%|*}"
  local category="${rest##*|}"
  if [[ "$SHORT" == "true" ]]; then
    echo "$pkgname"
  else
    printf "  %-40s %-12s %s\n" "$pkgname" "$version" "$category"
  fi
}

total=$(( ${#world_pkgs[@]} + ${#dep_pkgs[@]} ))

if [[ "$total" -eq 0 ]]; then
  kport_warn "No packages installed${FILTER_CATEGORY:+ in category '${FILTER_CATEGORY}'}."
  exit 0
fi

# ── World set (explicitly installed) ─────────────────────────────────────────

if [[ "$DEPS_ONLY" != "true" && ${#world_pkgs[@]} -gt 0 ]]; then
  [[ "$SHORT" != "true" ]] && kport_header "World set (${#world_pkgs[@]} package(s))"
  for entry in "${world_pkgs[@]}"; do
    _print_pkg "$entry"
  done
  [[ "$SHORT" != "true" ]] && echo ""
fi

# ── Dep-only (pulled in as dependencies) ─────────────────────────────────────

if [[ "$WORLD_ONLY" != "true" && ${#dep_pkgs[@]} -gt 0 ]]; then
  [[ "$SHORT" != "true" ]] && kport_header "Dependencies (${#dep_pkgs[@]} package(s))"
  for entry in "${dep_pkgs[@]}"; do
    _print_pkg "$entry"
  done
  [[ "$SHORT" != "true" ]] && echo ""
fi

if [[ "$SHORT" != "true" ]]; then
  echo -e "${C_DIM}${total} package(s) installed total  |  ${#world_pkgs[@]} explicit  |  ${#dep_pkgs[@]} dep-only${C_RESET}"
fi
