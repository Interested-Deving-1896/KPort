#!/usr/bin/env bash
# KPort pacscript — plasma/ksystemstats
# Promoted from generated/ — review and test before merging to main
#
# plugin based system monitoring daemon plugin based system monitoring daemon

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="ksystemstats"
pkgver="6.6.5"
pkgdesc="plugin based system monitoring daemon"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/ksystemstats-6.6.5.tar.xz"
)
sha256sums=(
  "6b5e2f2a6aaae97489e75818e7f83c2586578022760821c677cdebcefa542e36"
)

depends=(
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-networkmanager-qt"
  "kf6-solid"
  "libksysguard"
  "libnl-3-200"
  "libnl-route-3-200"
  "libsensors5"
  "libudev1"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-kio"
  "kf6-networkmanager-qt-dev"
  "kf6-solid"
  "libcap-dev"
  "plasma-libksysguard-dev"
  "libnl-3-dev"
  "libnl-route-3-dev"
  "libsensors-dev"
  "libudev-dev"
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
