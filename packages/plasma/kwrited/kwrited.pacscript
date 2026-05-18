#!/usr/bin/env bash
# KPort pacscript — plasma/kwrited
# Promoted from generated/ — review and test before merging to main
#
# Read and write console output to X

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kwrited"
pkgver="6.6.5"
pkgdesc="Read and write console output to X"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/workspace/kwrited"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kwrited-6.6.5.tar.xz"
)
sha256sums=(
  "b9df634be2aa1442d8247d6250a87d7dfb1ccd6f9bcd01c0e62102d5ab6936a7"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "debhelper"
  "kf6-extra-cmake-modules"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-knotifications"
  "kf6-kpty"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-test"
)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  _kport_lib="${KPORT_LIB_DIR:-/usr/lib/kport}/use-helpers.sh"
  [[ -f "$_kport_lib" ]] && source "$_kport_lib"

  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF) \
    -DBUILD_QCH=$(use_flag docs ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
