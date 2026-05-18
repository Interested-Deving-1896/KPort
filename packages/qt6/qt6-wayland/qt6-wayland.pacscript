#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-wayland
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 Wayland Client library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-wayland"
pkgver="6.10.2"
pkgdesc="Qt 6 Wayland Client library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtwayland-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "391998eb432719df26a6a67d8efdc67f8bf2afdd76c1ee3381ebff4fe7527ee2"
)

depends=(
  "qt6-base-dev"
)

makedepends=(
  "cmake"
  "libdrm-dev"
  "libegl1-mesa-dev"
  "libfontconfig-dev"
  "libgl-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libwayland-dev"
  "libxcomposite-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-svg-dev"
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
  "+wayland"
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
