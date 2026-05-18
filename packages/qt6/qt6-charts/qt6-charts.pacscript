#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-charts
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 charts library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-charts"
pkgver="6.10.2"
pkgdesc="Qt 6 charts library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtcharts-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "405116b4c5eded981484c4c154eb392d44b69b587342f1193181175e309f2c00"
)

depends=(
  "qt6-base-dev"
  "qt6-declarative-dev"
)

makedepends=(
  "cmake"
  "libgl-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-multimedia-dev"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-vk12"

KUSE=(
  "-vulkan"
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
