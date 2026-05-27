#!/usr/bin/env bash
# stage3/build.sh
#
# KDE Neon Stage3 bootstrap for KPort.
#
# Builds a minimal KDE Neon base environment ("Stage3") inside a target root,
# analogous to a Gentoo stage3 tarball. The result is a self-contained
# directory tree that can be:
#   - Chrooted into for further package installation
#   - Archived as a tarball and used as a container base layer
#   - Passed to bootc-image-builder as an OCI base
#
# The Stage3 consists of:
#   1. A debootstrap Ubuntu 24.04 (Noble) minimal root
#   2. KDE Neon apt archive added and authenticated
#   3. A curated set of base packages (plasma-desktop-minimal, kf6 runtime)
#   4. KPort itself installed into the target
#   5. A /etc/kport/channel file recording the channel
#
# Requirements (host):
#   debootstrap, qemu-user-static (for cross-arch), gpg, apt-get
#
# Usage: stage3/build.sh [options]
#
# Options:
#   --channel <c>    KDE Neon channel: stable|unstable|nightly (default: stable)
#   --arch <a>       Target architecture (default: host arch via dpkg --print-architecture)
#   --target <dir>   Root directory to bootstrap into (default: /tmp/kport-stage3-<arch>)
#   --tarball <f>    If set, archive the finished root to this .tar.gz path
#   --no-kde         Skip KDE Neon packages; produce Ubuntu-only minimal root
#   --no-kport       Skip KPort installation into the target
#   --clean          Remove target dir before starting (implies fresh bootstrap)
#   --dry-run        Print commands without executing
#   --help

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Defaults ──────────────────────────────────────────────────────────────────

CHANNEL="${KPORT_NEON_CHANNEL:-stable}"
ARCH="${KPORT_STAGE3_ARCH:-$(dpkg --print-architecture 2>/dev/null || echo amd64)}"
TARGET=""
TARBALL=""
NO_KDE=false
NO_KPORT=false
CLEAN=false
DRY_RUN=false

# ── Arg parsing ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)  CHANNEL="$2";  shift 2 ;;
    --arch)     ARCH="$2";     shift 2 ;;
    --target)   TARGET="$2";   shift 2 ;;
    --tarball)  TARBALL="$2";  shift 2 ;;
    --no-kde)   NO_KDE=true;   shift   ;;
    --no-kport) NO_KPORT=true; shift   ;;
    --clean)    CLEAN=true;    shift   ;;
    --dry-run)  DRY_RUN=true;  shift   ;;
    --help)
      sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done

# ── Derived values ────────────────────────────────────────────────────────────

[[ -z "$TARGET" ]] && TARGET="/tmp/kport-stage3-${ARCH}"

case "$CHANNEL" in
  stable)   NEON_SUITE="noble";   NEON_ARCHIVE_NAME="release"   ;;
  unstable) NEON_SUITE="noble";   NEON_ARCHIVE_NAME="unstable"  ;;
  nightly)  NEON_SUITE="noble";   NEON_ARCHIVE_NAME="nightly"   ;;
  *) echo "Invalid channel: $CHANNEL" >&2; exit 1 ;;
esac

NEON_ARCHIVE_URL="https://archive.neon.kde.org/${NEON_ARCHIVE_NAME}"
NEON_KEYRING_URL="https://archive.neon.kde.org/public.key"
UBUNTU_MIRROR="${KPORT_UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"

# For non-amd64 targets, use ports mirror
if [[ "$ARCH" != "amd64" && "$ARCH" != "i386" ]]; then
  UBUNTU_MIRROR="${KPORT_UBUNTU_PORTS_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

_log()  { echo "[stage3] $*"; }
_warn() { echo "[stage3] WARNING: $*" >&2; }
_die()  { echo "[stage3] ERROR: $*" >&2; exit 1; }

_run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

_chroot() {
  # Run a command inside the target chroot.
  # Uses qemu-user-static for cross-arch targets.
  _run chroot "$TARGET" "$@"
}

_apt_chroot() {
  # Run apt-get inside the chroot with a clean environment.
  _chroot env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get "$@"
}

# ── Preflight checks ──────────────────────────────────────────────────────────

_preflight() {
  _log "Preflight checks..."

  [[ $EUID -eq 0 ]] || _die "Must run as root (debootstrap requires root)"

  for cmd in debootstrap gpg curl apt-get; do
    command -v "$cmd" &>/dev/null || _die "Required command not found: $cmd"
  done

  # Cross-arch: need qemu-user-static
  local host_arch
  host_arch="$(dpkg --print-architecture)"
  if [[ "$ARCH" != "$host_arch" ]]; then
    command -v "qemu-${ARCH}-static" &>/dev/null \
      || dpkg -l qemu-user-static &>/dev/null \
      || _die "Cross-arch build for ${ARCH} requires qemu-user-static"
    _log "Cross-arch: ${host_arch} → ${ARCH} (qemu-user-static)"
  fi

  _log "  channel : ${CHANNEL} (${NEON_ARCHIVE_NAME})"
  _log "  arch    : ${ARCH}"
  _log "  target  : ${TARGET}"
  [[ -n "$TARBALL" ]] && _log "  tarball : ${TARBALL}"
}

# ── Step 1: debootstrap ───────────────────────────────────────────────────────

_debootstrap() {
  _log "Step 1: debootstrap Ubuntu Noble (${ARCH}) → ${TARGET}"

  if $CLEAN && [[ -d "$TARGET" ]]; then
    _log "  Removing existing target dir..."
    _run rm -rf "$TARGET"
  fi

  if [[ -d "${TARGET}/usr" ]]; then
    _log "  Target already bootstrapped — skipping debootstrap"
    return 0
  fi

  local debootstrap_args=(
    "--arch=${ARCH}"
    "--variant=minbase"
    "--include=ca-certificates,curl,gnupg,apt-transport-https,locales,tzdata"
    "noble"
    "$TARGET"
    "$UBUNTU_MIRROR"
  )

  # For cross-arch, pass the foreign flag and run second stage inside chroot
  local host_arch
  host_arch="$(dpkg --print-architecture)"
  if [[ "$ARCH" != "$host_arch" ]]; then
    debootstrap_args=("--foreign" "${debootstrap_args[@]}")
    _run debootstrap "${debootstrap_args[@]}"
    # Copy qemu binary into chroot
    local qemu_bin="/usr/bin/qemu-${ARCH}-static"
    [[ -f "$qemu_bin" ]] && _run cp "$qemu_bin" "${TARGET}/usr/bin/"
    _run chroot "$TARGET" /debootstrap/debootstrap --second-stage
  else
    _run debootstrap "${debootstrap_args[@]}"
  fi

  _log "  debootstrap complete"
}

# ── Step 2: Configure apt sources ────────────────────────────────────────────

_configure_apt() {
  _log "Step 2: Configure apt sources"

  # Ubuntu sources
  cat > "${TARGET}/etc/apt/sources.list" <<EOF
deb ${UBUNTU_MIRROR} noble main restricted universe multiverse
deb ${UBUNTU_MIRROR} noble-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} noble-security main restricted universe multiverse
EOF

  if ! $NO_KDE; then
    # Import KDE Neon signing key
    _log "  Importing KDE Neon archive key..."
    local keyring_path="${TARGET}/usr/share/keyrings/neon-archive-keyring.gpg"
    if $DRY_RUN; then
      echo "[dry-run] curl ${NEON_KEYRING_URL} | gpg --dearmor > ${keyring_path}"
    else
      curl -fsSL "$NEON_KEYRING_URL" \
        | gpg --dearmor \
        > "$keyring_path" \
        || _die "Failed to import KDE Neon archive key"
    fi

    # KDE Neon source
    cat > "${TARGET}/etc/apt/sources.list.d/neon.list" <<EOF
deb [signed-by=/usr/share/keyrings/neon-archive-keyring.gpg] ${NEON_ARCHIVE_URL} ${NEON_SUITE} main
EOF
    _log "  KDE Neon archive: ${NEON_ARCHIVE_URL}"
  fi

  # Refresh package lists
  _apt_chroot update -qq
}

# ── Step 3: Install base packages ────────────────────────────────────────────

# Minimal Ubuntu base packages always installed
BASE_PACKAGES=(
  bash
  coreutils
  util-linux
  procps
  iproute2
  iputils-ping
  less
  vim-tiny
  wget
  curl
  ca-certificates
  gnupg
  apt-transport-https
  locales
  tzdata
  sudo
  adduser
  passwd
  openssh-client
  git
)

# KDE Neon runtime packages (plasma-desktop-minimal equivalent)
KDE_PACKAGES=(
  plasma-desktop
  plasma-workspace
  kwin-x11
  kwin-wayland
  konsole
  dolphin
  kf6-kio
  kf6-kconfig
  kf6-kauth
  kf6-kcoreaddons
  kf6-kwidgetsaddons
  kf6-kservice
  kf6-knotifications
  kf6-kwindowsystem
  plasma-nm
  plasma-pa
  powerdevil
  breeze
  breeze-gtk-theme
  kde-spectacle
  sddm
  sddm-theme-breeze
  xorg
  xwayland
)

_install_packages() {
  _log "Step 3: Install packages"

  _log "  Installing base packages (${#BASE_PACKAGES[@]})..."
  _apt_chroot install -y --no-install-recommends "${BASE_PACKAGES[@]}"

  if ! $NO_KDE; then
    _log "  Installing KDE Neon packages (${#KDE_PACKAGES[@]})..."
    _apt_chroot install -y "${KDE_PACKAGES[@]}" \
      || _warn "Some KDE packages failed to install — check channel/arch compatibility"
  fi

  # Clean apt cache inside chroot
  _apt_chroot clean
  _run rm -rf "${TARGET}/var/lib/apt/lists/"*
}

# ── Step 4: Install KPort ─────────────────────────────────────────────────────

_install_kport() {
  $NO_KPORT && return 0
  _log "Step 4: Install KPort into target"

  local kport_dest="${TARGET}/opt/kport"
  _run mkdir -p "$kport_dest"
  _run rsync -a --exclude='.git' "${KPORT_ROOT}/" "${kport_dest}/"

  # Create /usr/local/bin/kport symlink inside chroot
  _run mkdir -p "${TARGET}/usr/local/bin"
  _run ln -sf /opt/kport/bin/kport "${TARGET}/usr/local/bin/kport"

  # Write channel config
  _run mkdir -p "${TARGET}/etc/kport"
  if $DRY_RUN; then
    echo "[dry-run] echo '${CHANNEL}' > ${TARGET}/etc/kport/channel"
  else
    echo "$CHANNEL" > "${TARGET}/etc/kport/channel"
  fi

  _log "  KPort installed at /opt/kport (channel: ${CHANNEL})"
}

# ── Step 5: Stage3 metadata ───────────────────────────────────────────────────

_write_metadata() {
  _log "Step 5: Write Stage3 metadata"

  local meta_dir="${TARGET}/etc/kport"
  _run mkdir -p "$meta_dir"

  if $DRY_RUN; then
    echo "[dry-run] write ${meta_dir}/stage3-release"
    return 0
  fi

  cat > "${meta_dir}/stage3-release" <<EOF
KPORT_STAGE3_DATE=$(date -u +%Y%m%dT%H%M%SZ)
KPORT_STAGE3_CHANNEL=${CHANNEL}
KPORT_STAGE3_ARCH=${ARCH}
KPORT_STAGE3_NEON_ARCHIVE=${NEON_ARCHIVE_URL}
KPORT_STAGE3_UBUNTU_SUITE=noble
EOF

  # os-release integration
  if [[ -f "${TARGET}/etc/os-release" ]]; then
    # Append KPort variant info
    cat >> "${TARGET}/etc/os-release" <<EOF

# KPort Stage3 overlay
VARIANT="KDE Neon (KPort Stage3)"
VARIANT_ID=kport-stage3
EOF
  fi

  _log "  Metadata written to ${meta_dir}/stage3-release"
}

# ── Step 6: Archive ───────────────────────────────────────────────────────────

_archive() {
  [[ -z "$TARBALL" ]] && return 0
  _log "Step 6: Archive → ${TARBALL}"

  local tarball_dir
  tarball_dir="$(dirname "$TARBALL")"
  _run mkdir -p "$tarball_dir"

  _run tar \
    --numeric-owner \
    --xattrs \
    --xattrs-include='*' \
    -czf "$TARBALL" \
    -C "$TARGET" \
    .

  local size
  size="$(du -sh "$TARBALL" 2>/dev/null | cut -f1)"
  _log "  Archive complete: ${TARBALL} (${size})"
}

# ── Main ──────────────────────────────────────────────────────────────────────

_preflight
_debootstrap
_configure_apt
_install_packages
_install_kport
_write_metadata
_archive

_log "Stage3 complete: ${TARGET}"
[[ -n "$TARBALL" ]] && _log "Tarball: ${TARBALL}"
