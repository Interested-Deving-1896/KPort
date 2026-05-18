#!/usr/bin/env bash
#
# resolver-check.sh
#
# Runs kport_resolve on a set of representative leaf packages and checks that:
#   - Resolution completes without "KPort package not found" warnings
#   - The resolved order is non-empty
#   - No circular dependency warnings are emitted
#
# Usage:
#   resolver-check.sh [--packages <pkg,...>] [--quiet]
#
# The default package set covers all four categories (frameworks, plasma, gear, qt6)
# and exercises the full dep chain from leaf apps down to qt6-base.
#
# Exit codes:
#   0  all checks passed
#   1  one or more resolver warnings or empty plans found

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="${KPORT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
QUIET=false
CUSTOM_PACKAGES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --packages) CUSTOM_PACKAGES="$2"; shift 2 ;;
    --quiet)    QUIET=true;           shift ;;
    --help)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Default representative leaf packages — one per category
DEFAULT_PACKAGES=(
  "kf6-karchive"       # frameworks/tier2 — exercises qt6-base chain
  "dolphin"            # gear — exercises kf6 + qt6 chain
  "kleopatra"          # gear/pim — exercises kpim6 chain
  "kwin-wayland"       # plasma — exercises plasma chain
  "qt6-declarative"    # qt6 — exercises qt6-base
)

if [[ -n "$CUSTOM_PACKAGES" ]]; then
  IFS=',' read -ra CHECK_PACKAGES <<< "$CUSTOM_PACKAGES"
else
  CHECK_PACKAGES=("${DEFAULT_PACKAGES[@]}")
fi

# ── Bootstrap kport env ───────────────────────────────────────────────────────

export KPORT_ROOT
export KPORT_LIB="${KPORT_ROOT}/lib/kport"
export KPORT_DB="${KPORT_ROOT}/.ci-db"          # isolated throwaway DB
export KPORT_CONF="${KPORT_ROOT}/config"
export KPORT_RESOLVE_ALL=true                    # resolve full tree, ignore installed

mkdir -p "${KPORT_DB}/installed"

source "${KPORT_LIB}/common.sh"
source "${KPORT_LIB}/resolve.sh"

# ── Run resolver checks ───────────────────────────────────────────────────────

errors=0
info() { [[ "$QUIET" == "true" ]] || echo "$*"; }

info "Resolver dry-run for ${#CHECK_PACKAGES[@]} package(s)"
info ""

for pkg in "${CHECK_PACKAGES[@]}"; do
  info "  resolving: ${pkg}"

  # Capture both stdout (plan) and stderr (warnings)
  resolver_out=$(kport_resolve "$pkg" 2>&1)
  plan_lines=$(kport_resolve "$pkg" 2>/dev/null | wc -l)

  # Check for missing KPort package warnings
  missing=$(echo "$resolver_out" | grep "KPort package not found:" || true)
  circular=$(echo "$resolver_out" | grep "Circular dependency" || true)

  if [[ -n "$missing" ]]; then
    echo "  ERROR: ${pkg}: unresolved KPort deps:" >&2
    echo "$missing" | sed 's/^/    /' >&2
    (( errors++ )) || true
  fi

  if [[ -n "$circular" ]]; then
    echo "  ERROR: ${pkg}: circular dependency detected:" >&2
    echo "$circular" | sed 's/^/    /' >&2
    (( errors++ )) || true
  fi

  if [[ "$plan_lines" -eq 0 ]]; then
    echo "  ERROR: ${pkg}: resolver returned empty plan" >&2
    (( errors++ )) || true
  else
    info "    → ${plan_lines} package(s) in install order"
  fi
done

# ── Overlay resolution test ───────────────────────────────────────────────────
# Verify that kport_find_pacscript returns the overlay version of kf6-karchive
# when the example overlay is enabled in repositories.yml.

info ""
info "  overlay resolution: kf6-karchive (example overlay should shadow main tree)"

overlay_ps=$(kport_find_pacscript "kf6-karchive" 2>/dev/null)
if [[ "$overlay_ps" == *"overlays/example"* ]]; then
  info "    → overlay hit: ${overlay_ps##${KPORT_ROOT}/}"
else
  echo "  ERROR: kf6-karchive resolved to main tree instead of example overlay" >&2
  echo "    got: ${overlay_ps}" >&2
  (( errors++ )) || true
fi

# Verify the overlay pacscript has the expected marker in pkgdesc
overlay_desc=$(kport_pacscript_var "$overlay_ps" pkgdesc 2>/dev/null)
if [[ "$overlay_desc" == *"example overlay"* ]]; then
  info "    → pkgdesc confirms overlay version"
else
  echo "  ERROR: overlay pkgdesc does not contain 'example overlay' marker" >&2
  echo "    got: ${overlay_desc}" >&2
  (( errors++ )) || true
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────

rm -rf "${KPORT_DB}"

echo ""
echo "Resolver check complete — ${errors} error(s)"

if (( errors > 0 )); then
  echo "FAIL" >&2
  exit 1
fi

echo "OK"
exit 0
