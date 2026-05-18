#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-remoteobjects
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 Remote Objects library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-remoteobjects"
pkgver="6.10.2"
pkgdesc="Qt 6 Remote Objects library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtremoteobjects-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "bc683f044fe74dcf06c2b47f31fff2d967b5ac81896620108697dcc942eb65cd"
)

depends=(
  "qt6-base-dev"
  "qt6-connectivity"
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
  "qt6-connectivity-dev"
  "qt6-declarative-dev"
  "qt6-websockets-dev"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

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
