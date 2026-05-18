#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-interfaceframework
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt Interface Framework Generator Qt Interface Framework provides a way for you

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-interfaceframework"
pkgver="6.10.2"
pkgdesc="Qt Interface Framework — code generator and runtime for feature-based APIs"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://github.com/qt/qtinterfaceframework/archive/refs/tags/v6.10.2.tar.gz"
)
sha256sums=(
  "3216e85233c5a3853471698acc54a54db26d7f6781c3a5578847bd4d3a272a47"
)

depends=(
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "debhelper"
  "flex"
  "mold"
  "ninja-build"
  "pkg-config"
  "pkg-kde-tools"
  "python3-virtualenv"
  "qt6-base-dev"
  "qt6-remoteobjects-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

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
