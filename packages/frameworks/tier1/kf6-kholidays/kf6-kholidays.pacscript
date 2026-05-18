#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kholidays
# Promoted from generated/ — review and test before merging to main
#
# Holiday calculation library

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kholidays"
pkgver="6.26.0"
pkgdesc="Holiday calculation library"
url="https://api.kde.org/frameworks/kholidays/html/index.html"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kholidays-6.26.0.tar.xz"
)
sha256sums=(
  "fc4f46cb5bb8e4766f550fe1a8b401731d797fcf6afa7cb53679048c215a60be"
)

depends=(
  "qt6-base-dev"
  "qt6-declarative-dev"
)

makedepends=(
  "bison"
  "cmake"
  "doxygen"
  "flex"
  "graphviz"
  "kf6-extra-cmake-modules"
  "qt6-base-dev"
  "qt6-declarative-dev"
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
