#!/usr/bin/env bash
# kport-binhost.sh — KPort binary package host (binhost) management
#
# Adapted from Gentoo's binhost-utils concept for KPort's Debian/Ubuntu
# package ecosystem. Manages a local or remote directory of pre-built .deb
# packages that kport install can pull instead of building from source.
#
# The binhost stores packages as:
#   <binhost_root>/<channel>/<arch>/<package>_<version>_<arch>.deb
#   <binhost_root>/<channel>/<arch>/Packages.gz   (apt-compatible index)
#   <binhost_root>/<channel>/<arch>/Release        (apt Release file)
#
# This layout is intentionally apt-compatible so the binhost can be added
# as a standard apt source if desired.
#
# Usage:
#   kport-binhost.sh add    <package> <deb_file> [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh remove <package>            [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh list                        [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh index                       [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh fetch  <package>            [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh push   <remote_url>         [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh pull   <remote_url>         [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh verify <package>            [--channel CHANNEL] [--arch ARCH]
#   kport-binhost.sh clean  [--keep-versions N]  [--channel CHANNEL] [--arch ARCH]
#
# Environment:
#   KPORT_BINHOST_ROOT    Local binhost root dir (default: ~/.cache/kport/binhost)
#   KPORT_BINHOST_REMOTE  Remote binhost URL for push/pull (rsync or https)
#   KPORT_NEON_CHANNEL    Default channel: stable|unstable|nightly (default: stable)
#   KPORT_BINHOST_ARCH    Default arch (default: dpkg --print-architecture)
#   KPORT_BINHOST_SIGN    GPG key ID for signing Release files (optional)

set -euo pipefail

KPORT_BINHOST_ROOT="${KPORT_BINHOST_ROOT:-${HOME}/.cache/kport/binhost}"
KPORT_BINHOST_REMOTE="${KPORT_BINHOST_REMOTE:-}"
KPORT_NEON_CHANNEL="${KPORT_NEON_CHANNEL:-stable}"
KPORT_BINHOST_ARCH="${KPORT_BINHOST_ARCH:-$(dpkg --print-architecture 2>/dev/null || echo amd64)}"
KPORT_BINHOST_SIGN="${KPORT_BINHOST_SIGN:-}"
KPORT_BINHOST_KEEP_VERSIONS="${KPORT_BINHOST_KEEP_VERSIONS:-3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { echo "[kport-binhost] $*"; }
warn()  { echo "[kport-binhost] WARN: $*" >&2; }
die()   { echo "[kport-binhost] ERROR: $*" >&2; exit 1; }

require_cmd() { command -v "$1" &>/dev/null || die "'$1' not found — install $2"; }

# Returns the binhost directory for a channel + arch
_binhost_dir() {
  local channel="${1:-$KPORT_NEON_CHANNEL}"
  local arch="${2:-$KPORT_BINHOST_ARCH}"
  echo "${KPORT_BINHOST_ROOT}/${channel}/${arch}"
}

# Extracts the package name from a .deb filename
# e.g. kf6-karchive_6.3.0+p24.04+git20250501T120000Z_amd64.deb → kf6-karchive
_deb_pkgname() {
  basename "$1" | cut -d_ -f1
}

# Extracts the version from a .deb filename
_deb_version() {
  basename "$1" | cut -d_ -f2
}

# Extracts the arch from a .deb filename
_deb_arch() {
  basename "$1" | cut -d_ -f3 | sed 's/\.deb$//'
}

# ── Arg parsing ───────────────────────────────────────────────────────────────

SUBCMD="${1:-}"
[[ -z "$SUBCMD" ]] && { echo "Usage: kport-binhost.sh <subcommand> [args]"; echo "Try: kport-binhost.sh --help"; exit 1; }
shift

CHANNEL="$KPORT_NEON_CHANNEL"
ARCH="$KPORT_BINHOST_ARCH"
KEEP_VERSIONS="$KPORT_BINHOST_KEEP_VERSIONS"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)       CHANNEL="$2";       shift 2 ;;
    --arch)          ARCH="$2";          shift 2 ;;
    --keep-versions) KEEP_VERSIONS="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *)  POSITIONAL+=("$1"); shift ;;
  esac
done

# ── Subcommands ───────────────────────────────────────────────────────────────

# add <package> <deb_file>
# Copies a .deb into the binhost and re-indexes.
cmd_add() {
  local pkg="${POSITIONAL[0]:-}"
  local deb="${POSITIONAL[1]:-}"
  [[ -z "$pkg" || -z "$deb" ]] && die "Usage: kport-binhost.sh add <package> <deb_file>"
  [[ -f "$deb" ]] || die "File not found: $deb"
  [[ "$deb" == *.deb ]] || die "Expected a .deb file: $deb"

  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"
  mkdir -p "$dest_dir"

  local dest_file="${dest_dir}/$(basename "$deb")"
  cp "$deb" "$dest_file"
  info "Added: ${dest_file}"

  cmd_index
}

# remove <package>
# Removes all versions of a package from the binhost and re-indexes.
cmd_remove() {
  local pkg="${POSITIONAL[0]:-}"
  [[ -z "$pkg" ]] && die "Usage: kport-binhost.sh remove <package>"

  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"

  local removed=0
  while IFS= read -r -d '' deb; do
    rm -f "$deb"
    info "Removed: $(basename "$deb")"
    (( removed++ )) || true
  done < <(find "$dest_dir" -maxdepth 1 -name "${pkg}_*.deb" -print0 2>/dev/null)

  if [[ $removed -eq 0 ]]; then
    warn "No packages found for: ${pkg} (channel=${CHANNEL}, arch=${ARCH})"
    exit 1
  fi

  cmd_index
}

# list [--channel CHANNEL] [--arch ARCH]
# Lists all packages in the binhost.
cmd_list() {
  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"

  if [[ ! -d "$dest_dir" ]]; then
    info "Binhost is empty (${dest_dir} does not exist)"
    return 0
  fi

  local count=0
  printf "%-40s %-30s %s\n" "PACKAGE" "VERSION" "ARCH"
  printf "%-40s %-30s %s\n" "-------" "-------" "----"
  while IFS= read -r -d '' deb; do
    local name version arch
    name="$(_deb_pkgname "$deb")"
    version="$(_deb_version "$deb")"
    arch="$(_deb_arch "$deb")"
    printf "%-40s %-30s %s\n" "$name" "$version" "$arch"
    (( count++ )) || true
  done < <(find "$dest_dir" -maxdepth 1 -name "*.deb" -print0 2>/dev/null | sort -z)

  echo ""
  info "${count} package(s) in binhost (channel=${CHANNEL}, arch=${ARCH})"
}

# index [--channel CHANNEL] [--arch ARCH]
# Regenerates Packages.gz and Release for the binhost directory.
# Requires: dpkg-scanpackages (from dpkg-dev), gzip
cmd_index() {
  require_cmd dpkg-scanpackages "dpkg-dev"
  require_cmd gzip              "gzip"

  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"
  mkdir -p "$dest_dir"

  info "Indexing ${dest_dir}..."

  # Generate Packages file
  (
    cd "$dest_dir"
    dpkg-scanpackages --multiversion . /dev/null 2>/dev/null \
      | gzip -9c > Packages.gz
  )

  # Generate a minimal Release file
  local suite="noble"
  local date_str
  date_str="$(date -u '+%a, %d %b %Y %H:%M:%S UTC')"
  local packages_size packages_md5 packages_sha256
  packages_size="$(wc -c < "${dest_dir}/Packages.gz")"
  packages_md5="$(md5sum "${dest_dir}/Packages.gz" | cut -d' ' -f1)"
  packages_sha256="$(sha256sum "${dest_dir}/Packages.gz" | cut -d' ' -f1)"

  cat > "${dest_dir}/Release" <<EOF
Origin: KPort Binhost
Label: KPort
Suite: ${suite}
Codename: ${suite}
Date: ${date_str}
Architectures: ${ARCH}
Components: main
Description: KPort binary package host (channel=${CHANNEL})
MD5Sum:
 ${packages_md5} ${packages_size} Packages.gz
SHA256:
 ${packages_sha256} ${packages_size} Packages.gz
EOF

  # Optionally sign the Release file
  if [[ -n "$KPORT_BINHOST_SIGN" ]]; then
    require_cmd gpg "gnupg"
    gpg --default-key "$KPORT_BINHOST_SIGN" \
        --armor --detach-sign \
        --output "${dest_dir}/Release.gpg" \
        "${dest_dir}/Release" \
      && info "Signed Release with key: ${KPORT_BINHOST_SIGN}" \
      || warn "GPG signing failed — Release.gpg not written"
  fi

  local deb_count
  deb_count="$(find "$dest_dir" -maxdepth 1 -name "*.deb" | wc -l)"
  info "Index updated: ${deb_count} package(s)"
}

# fetch <package> [--channel CHANNEL] [--arch ARCH]
# Fetches the latest .deb for a package from the binhost into the current dir.
# If KPORT_BINHOST_REMOTE is set, fetches from the remote; otherwise from local.
cmd_fetch() {
  local pkg="${POSITIONAL[0]:-}"
  [[ -z "$pkg" ]] && die "Usage: kport-binhost.sh fetch <package>"

  if [[ -n "$KPORT_BINHOST_REMOTE" ]]; then
    _fetch_remote "$pkg"
  else
    _fetch_local "$pkg"
  fi
}

_fetch_local() {
  local pkg="$1"
  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"

  # Find the latest version (sort by version, take last)
  local latest
  latest="$(find "$dest_dir" -maxdepth 1 -name "${pkg}_*.deb" 2>/dev/null \
    | sort -V | tail -1)"

  [[ -z "$latest" ]] && die "Package not found in local binhost: ${pkg} (channel=${CHANNEL}, arch=${ARCH})"

  cp "$latest" .
  info "Fetched: $(basename "$latest")"
}

_fetch_remote() {
  local pkg="$1"
  require_cmd curl "curl"

  local remote_base="${KPORT_BINHOST_REMOTE%/}/${CHANNEL}/${ARCH}"

  # Parse Packages.gz to find the latest version
  local packages_url="${remote_base}/Packages.gz"
  local packages_data
  packages_data="$(curl -fsSL "$packages_url" | gunzip -c 2>/dev/null)" \
    || die "Failed to fetch Packages.gz from: ${packages_url}"

  # Find the Filename field for the requested package
  local deb_path
  deb_path="$(echo "$packages_data" \
    | awk -v pkg="$pkg" '
        /^Package: / { current = $2 }
        /^Filename: / && current == pkg { print $2; exit }
      ')"

  [[ -z "$deb_path" ]] && die "Package not found in remote binhost: ${pkg}"

  local deb_url="${KPORT_BINHOST_REMOTE%/}/${deb_path}"
  info "Fetching: ${deb_url}"
  curl -fsSL -O "$deb_url" || die "Download failed: ${deb_url}"
  info "Fetched: $(basename "$deb_url")"
}

# push <remote_url>
# Pushes the local binhost to a remote location via rsync.
cmd_push() {
  local remote="${POSITIONAL[0]:-${KPORT_BINHOST_REMOTE}}"
  [[ -z "$remote" ]] && die "Usage: kport-binhost.sh push <remote_url>  (or set KPORT_BINHOST_REMOTE)"
  require_cmd rsync "rsync"

  local src_dir
  src_dir="$(_binhost_dir "$CHANNEL" "$ARCH")/"

  [[ -d "$src_dir" ]] || die "Local binhost dir not found: ${src_dir}"

  local dest="${remote%/}/${CHANNEL}/${ARCH}/"
  info "Pushing ${src_dir} → ${dest}"
  rsync -avz --progress "$src_dir" "$dest" \
    || die "rsync push failed"
  info "Push complete"
}

# pull <remote_url>
# Pulls packages from a remote binhost into the local binhost.
cmd_pull() {
  local remote="${POSITIONAL[0]:-${KPORT_BINHOST_REMOTE}}"
  [[ -z "$remote" ]] && die "Usage: kport-binhost.sh pull <remote_url>  (or set KPORT_BINHOST_REMOTE)"
  require_cmd rsync "rsync"

  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"
  mkdir -p "$dest_dir"

  local src="${remote%/}/${CHANNEL}/${ARCH}/"
  info "Pulling ${src} → ${dest_dir}/"
  rsync -avz --progress "$src" "${dest_dir}/" \
    || die "rsync pull failed"
  info "Pull complete"
}

# verify <package>
# Verifies the SHA256 checksum of a package in the binhost against Packages.gz.
cmd_verify() {
  local pkg="${POSITIONAL[0]:-}"
  [[ -z "$pkg" ]] && die "Usage: kport-binhost.sh verify <package>"
  require_cmd sha256sum "coreutils"

  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"
  local packages_gz="${dest_dir}/Packages.gz"

  [[ -f "$packages_gz" ]] || die "Packages.gz not found — run 'kport-binhost.sh index' first"

  # Parse Packages.gz for the package's SHA256 and Filename
  local pkg_sha256 pkg_filename
  pkg_sha256="$(gunzip -c "$packages_gz" \
    | awk -v pkg="$pkg" '
        /^Package: / { current = $2 }
        /^SHA256: /  && current == pkg { print $2 }
      ' | tail -1)"
  pkg_filename="$(gunzip -c "$packages_gz" \
    | awk -v pkg="$pkg" '
        /^Package: / { current = $2 }
        /^Filename: / && current == pkg { print $2 }
      ' | tail -1)"

  [[ -z "$pkg_sha256" ]] && die "Package not found in index: ${pkg}"

  local deb_path="${dest_dir}/$(basename "$pkg_filename")"
  [[ -f "$deb_path" ]] || die "Package file not found: ${deb_path}"

  local actual_sha256
  actual_sha256="$(sha256sum "$deb_path" | cut -d' ' -f1)"

  if [[ "$actual_sha256" == "$pkg_sha256" ]]; then
    info "✔ ${pkg}: SHA256 OK"
  else
    warn "✘ ${pkg}: SHA256 MISMATCH"
    warn "  expected: ${pkg_sha256}"
    warn "  actual:   ${actual_sha256}"
    exit 1
  fi
}

# clean [--keep-versions N]
# Removes old versions of packages, keeping the N most recent per package.
cmd_clean() {
  local dest_dir
  dest_dir="$(_binhost_dir "$CHANNEL" "$ARCH")"

  [[ -d "$dest_dir" ]] || { info "Binhost is empty — nothing to clean"; return 0; }

  local removed=0

  # Group .deb files by package name, sort by version, remove oldest
  declare -A pkg_debs
  while IFS= read -r -d '' deb; do
    local name
    name="$(_deb_pkgname "$deb")"
    pkg_debs["$name"]+="${deb}"$'\n'
  done < <(find "$dest_dir" -maxdepth 1 -name "*.deb" -print0 2>/dev/null)

  for pkg in "${!pkg_debs[@]}"; do
    local debs_sorted
    mapfile -t debs_sorted < <(echo -n "${pkg_debs[$pkg]}" | sort -V)
    local total=${#debs_sorted[@]}
    local to_remove=$(( total - KEEP_VERSIONS ))
    if [[ $to_remove -gt 0 ]]; then
      for (( i=0; i<to_remove; i++ )); do
        rm -f "${debs_sorted[$i]}"
        info "Removed old version: $(basename "${debs_sorted[$i]}")"
        (( removed++ )) || true
      done
    fi
  done

  if [[ $removed -gt 0 ]]; then
    cmd_index
    info "Cleaned ${removed} old package(s) (kept ${KEEP_VERSIONS} versions per package)"
  else
    info "Nothing to clean (all packages have ≤ ${KEEP_VERSIONS} versions)"
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$SUBCMD" in
  add)    cmd_add    ;;
  remove) cmd_remove ;;
  list)   cmd_list   ;;
  index)  cmd_index  ;;
  fetch)  cmd_fetch  ;;
  push)   cmd_push   ;;
  pull)   cmd_pull   ;;
  verify) cmd_verify ;;
  clean)  cmd_clean  ;;
  --help|-h)
    sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
    exit 0
    ;;
  *)
    die "Unknown subcommand: ${SUBCMD}. Try: add | remove | list | index | fetch | push | pull | verify | clean"
    ;;
esac
