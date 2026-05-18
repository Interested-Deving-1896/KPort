#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-doc
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 documentation in Qt's help format Qt is a cross-platform C++ application

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-doc"
pkgver="6.10.2"
pkgdesc="Qt 6 documentation in Qt's help format"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtdoc-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "8c14a9ed1067facb52eb88a37ce5bf7a1b1ffb8829c30dd2792d05e02cb83704"
)

depends=(
  "qt6-3d-doc"
  "qt6-5compat-doc"
  "qt6-charts-doc"
  "qt6-connectivity-doc"
  "qt6-datavis3d-doc"
  "qt6-declarative-doc"
  "qt6-graphs-doc"
  "qt6-grpc-doc"
  "qt6-httpserver-doc"
  "qt6-imageformats-doc"
  "qt6-location-doc"
  "qt6-multimedia-doc"
  "qt6-networkauth-doc"
  "qt6-positioning-doc"
  "qt6-quick3d-doc"
  "qt6-quick3dphysics-doc"
  "qt6-remoteobjects-doc"
  "qt6-scxml-doc"
  "qt6-sensors-doc"
  "qt6-serialbus-doc"
  "qt6-serialport-doc"
  "qt6-shadertools-doc"
  "qt6-speech-doc"
  "qt6-svg-doc"
  "qt6-tools-doc"
  "qt6-virtualkeyboard-doc"
  "qt6-wayland-doc"
  "qt6-webchannel-doc"
  "qt6-webengine-doc"
  "qt6-websockets-doc"
  "qt6-webview-doc"
)

makedepends=(
  "cmake"
  "libcups2-dev"
  "libgtk-3-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libx11-xcb-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-httpserver-dev"
  "qt6-multimedia-dev"
  "qt6-quick3d-dev"
  "qt6-quick3dphysics-dev"
  "qt6-svg-dev"
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
