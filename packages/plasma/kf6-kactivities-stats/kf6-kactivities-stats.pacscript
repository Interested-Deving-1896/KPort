#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-kactivities-stats
# Promoted from generated/ — review and test before merging to main
#
# Activities Stats Libary

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kactivities-stats"
pkgver="6.6.5"
pkgdesc="Activities Stats Libary"
url="https://projects.kde.org/projects/frameworks/kactivities-stats"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/plasma-activities-stats-6.6.5.tar.xz"
)
sha256sums=(
  "93af76f5c4171d089cd9a4f502bba63a65f2a371aa1a83c0c6cfb0021a5efba6"
)

depends=(
  "kf6-kconfig"
  "plasma-activities"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kactivities"
  "kf6-kconfig"
  "libboost-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"
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
