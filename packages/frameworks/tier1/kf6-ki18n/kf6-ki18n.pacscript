#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-ki18n
# Promoted from generated/ — review and test before merging to main
#
# Advanced internationalization framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-ki18n"
pkgver="6.26.0"
pkgdesc="Advanced internationalization framework"
url="https://projects.kde.org/projects/frameworks/ki18n"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/ki18n-6.26.0.tar.xz"
)
sha256sums=(
  "484aad486bfafef6c86d8d5b26529258e67c74c96250c1ac212ddf568448c7c0"
)

depends=(
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "doxygen"
  "gettext"
  "graphviz"
  "kf6-extra-cmake-modules"
  "python3"
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
