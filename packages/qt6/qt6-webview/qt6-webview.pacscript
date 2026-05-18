#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-webview
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 WebView library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-webview"
pkgver="6.10.2"
pkgdesc="Qt 6 WebView library Qt is a cross-platform C++ application framework"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtwebview-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "7ec406ff0998900ccef0ff8e4e5b1fbf15e4e18f3b43eb72e8b2aeda0dd0eab4"
)

depends=(
  "fontconfig"
  "qt6-webengine"
)

makedepends=(
  "cmake"
  "libgl-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libxcb-xkb-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-webengine-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-vk12"

KUSE=(
  "+x11"
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
