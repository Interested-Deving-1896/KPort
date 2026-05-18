#!/usr/bin/env bash
# scripts/kport/fill-sha256.sh
#
# Fetch the source tarball for each pacscript that has a SKIP sha256sum
# placeholder and replace it with the real checksum.
#
# Usage:
#   fill-sha256.sh [--dir <generated-dir>] [--package <pkgname>] [--dry-run]
#
# Options:
#   --dir <path>       Root directory to search for pacscripts
#                      (default: <repo-root>/generated)
#   --package <name>   Process only the named package
#   --dry-run          Print what would be done without modifying files
#   --force            Re-fetch and update even if sha256sum is already set
#
# Requirements: curl, sha256sum
#
# The script downloads each tarball to a temp file, computes the sha256,
# patches the pacscript in-place, then deletes the temp file.  It never
# stores tarballs permanently.
#
# Exit codes:
#   0  all processed successfully
#   1  one or more packages failed (details printed to stderr)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

GENERATED_DIR="${KPORT_ROOT}/generated"
FILTER_PACKAGE=""
DRY_RUN=false
FORCE=false

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)       GENERATED_DIR="$2"; shift 2 ;;
    --package)   FILTER_PACKAGE="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --force)     FORCE=true; shift ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { echo "[fill-sha256] $*"; }
warn()  { echo "[warn] $*" >&2; }
error() { echo "[error] $*" >&2; exit 1; }

# Extract the first source URL from a pacscript's source=() array.
extract_source_url() {
  local file="$1"
  # Extract the content of the source=(...) block, then pull the first https:// URL.
  awk '/^source=\(/{found=1} found{print} /^\)/{if(found) exit}' "$file" \
    | grep -oP '(?<=")(https://[^"]+)(?=")' \
    | head -1
}

# Check whether the sha256sums array still contains a SKIP placeholder.
has_skip_sha256() {
  local file="$1"
  grep -q '"SKIP"' "$file"
}

# Patch the SKIP placeholder in sha256sums with the real checksum.
# Replaces the first occurrence of "SKIP" (with its trailing comment if any).
patch_sha256() {
  local file="$1"
  local checksum="$2"
  # Replace:  "SKIP"   # replace with actual sha256 after download
  # With:     "<checksum>"
  sed -i "s|\"SKIP\".*# replace with actual sha256 after download|\"${checksum}\"|" "$file"
}

# ── Main ──────────────────────────────────────────────────────────────────────

[[ -d "$GENERATED_DIR" ]] || error "Generated dir not found: $GENERATED_DIR"
for cmd in curl sha256sum; do
  command -v "$cmd" &>/dev/null || error "Required command not found: $cmd"
done

[[ "$DRY_RUN"  == "true" ]] && info "Dry run — no files will be modified"
[[ "$FORCE"    == "true" ]] && info "Force mode — re-fetching even if sha256 already set"

total=0
updated=0
skipped=0
failed=0
failed_pkgs=()

# Collect pacscripts
mapfile -t pacscripts < <(find "$GENERATED_DIR" -name "*.pacscript" | sort)

for file in "${pacscripts[@]}"; do
  pkg=$(basename "$file" .pacscript)

  # Apply package filter
  if [[ -n "$FILTER_PACKAGE" && "$pkg" != "$FILTER_PACKAGE" ]]; then
    continue
  fi

  (( total++ )) || true

  # Skip if already has a real checksum (unless --force)
  if ! has_skip_sha256 "$file"; then
    if [[ "$FORCE" != "true" ]]; then
      info "  skip  $pkg (sha256 already set)"
      (( skipped++ )) || true
      continue
    fi
  fi

  # Extract source URL
  url=$(extract_source_url "$file")
  if [[ -z "$url" ]]; then
    warn "  $pkg: no source URL found — skipping"
    (( skipped++ )) || true
    continue
  fi

  info "  $pkg"
  info "    url: $url"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "    [dry-run] would fetch and compute sha256"
    continue
  fi

  # Download to temp file
  tmpfile=$(mktemp --suffix=".tar.xz")
  trap 'rm -f "$tmpfile"' EXIT

  if ! curl -sfL --retry 3 --retry-delay 2 -o "$tmpfile" "$url"; then
    warn "  $pkg: download failed: $url"
    rm -f "$tmpfile"
    (( failed++ )) || true
    failed_pkgs+=("$pkg")
    trap - EXIT
    continue
  fi

  # Compute checksum
  checksum=$(sha256sum "$tmpfile" | cut -d' ' -f1)
  rm -f "$tmpfile"
  trap - EXIT

  info "    sha256: $checksum"

  # Patch the pacscript
  patch_sha256 "$file" "$checksum"
  (( updated++ )) || true
done

echo ""
info "════════════════════════════════════════"
info "Done"
info "  Processed : $total"
info "  Updated   : $updated"
info "  Skipped   : $skipped"
info "  Failed    : $failed"
[[ ${#failed_pkgs[@]} -gt 0 ]] && info "  Failed pkgs: ${failed_pkgs[*]}"
info "════════════════════════════════════════"

[[ "$failed" -gt 0 ]] && exit 1
exit 0
