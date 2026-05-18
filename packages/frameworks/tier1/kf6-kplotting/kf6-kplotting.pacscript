#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kplotting
# Promoted from generated/ — review and test before merging to main
#
# Lightweight plotting framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kplotting"
pkgver="6.26.0"
pkgdesc="Lightweight plotting framework"
url="https://projects.kde.org/projects/frameworks/kplotting"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kplotting-6.26.0.tar.xz"
)
sha256sums=(
  "bb120f446e6bfc376129e03663e4b3b9e7146abc948ccc68da19187840f9f181"
)

depends=(
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
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
