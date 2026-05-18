#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-tools
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt 6 Designer library Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-tools"
pkgver="6.10.2"
pkgdesc="Qt 6 Designer library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qttools-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "1e3d2c07c1fd76d2425c6eaeeaa62ffaff5f79210c4e1a5bc2a6a9db668d5b24"
)

depends=(
  "qt6-base-dev"
  "qt6-declarative-dev"
)

makedepends=(
  "clang"
  "cmake"
  "libclang-dev"
  "libcurl4-openssl-dev"
  "libedit-dev"
  "libgl-dev"
  "libssl-dev"
  "libvulkan-dev"
  "libxcb-xkb-dev"
  "libxkbcommon-dev"
  "libzstd-dev"
  "llvm"
  "llvm-dev"
  "mold"
  "ninja-build"
  "pkgconf"
  "pkg-kde-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

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
