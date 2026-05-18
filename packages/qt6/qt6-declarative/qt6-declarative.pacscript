#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-declarative
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 QML module Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-declarative"
pkgver="6.10.2"
pkgdesc="Qt 6 QML module"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtdeclarative-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "a249914ff66cdcdbf0df8b5ffad997a2ee6dce01cc17d43c6cc56fdc1d0f4b0f"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "libgl-dev"
  "liblttng-ust-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libxkbcommon-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-languageserver-dev"
  "qt6-location-dev"
  "qt6-positioning-dev"
  "qt6-shadertools-dev"
  "qt6-svg-dev"
  "qt6-tools-dev"
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
