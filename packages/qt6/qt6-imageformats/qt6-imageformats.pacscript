#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-imageformats
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 Image Formats plugins Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-imageformats"
pkgver="6.10.2"
pkgdesc="Qt 6 Image Formats plugins"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtimageformats-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "8b8f9c718638081e7b3c000e7f31910140b1202a98e98df5d1b496fe6f639d67"
)

depends=(
  "libjasper4"
  "libmng2"
  "libtiff5"
  "libwebp7"
  "libwebpdemux2"
  "libwebpmux3"
  "qt6-base"
)

makedepends=(
  "cmake"
  "libgl-dev"
  "libjasper-dev"
  "libmng-dev"
  "libtiff-dev"
  "libwebp-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl2"

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
