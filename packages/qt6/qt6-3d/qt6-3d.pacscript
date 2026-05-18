#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-3d
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 3D Core library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-3d"
pkgver="6.10.2"
pkgdesc="Qt 6 3D Core library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qt3d-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "febbca9d491feca0fa2d770e912590b4ef18e461f739ca6e855ea62a488bbb6d"
)

depends=(
  "libassimp5"
  "qt6-base"
  "qt6-declarative"
  "qt6-shadertools"
)

makedepends=(
  "cmake"
  "libassimp-dev"
  "libgl-dev"
  "libgl1-mesa-dri"
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
  "qt6-quick3d-dev"
  "qt6-shadertools-dev"
  "xauth"
  "xvfb"
  "zlib1g-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl4"

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
