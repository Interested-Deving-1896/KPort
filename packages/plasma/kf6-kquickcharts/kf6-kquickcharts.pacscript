#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-kquickcharts
# Promoted from generated/ — review and test before merging to main
#
# A QtQuick module providing high-performance charts.

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kquickcharts"
pkgver="6.26.0"
pkgdesc="A QtQuick module providing high-performance charts."
url="https://invent.kde.org/kde/kquickcharts"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kquickcharts-6.26.0.tar.xz"
)
sha256sums=(
  "ae3e0784a2a2d1396cb751cc61f43a567e066d6434971246b1a18365481a1b52"
)

depends=(
  "kf6-kirigami2"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kconfig-dev"
  "kf6-kdeclarative-dev"
  "kf6-kirigami2-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-shadertools-dev"
  "qt6-tools-dev"
  "xauth"
  "xvfb"
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
