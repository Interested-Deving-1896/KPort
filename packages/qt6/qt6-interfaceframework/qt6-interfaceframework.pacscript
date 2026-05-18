#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-interfaceframework
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt Interface Framework Generator Qt Interface Framework provides a way for you

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-interfaceframework"
pkgver="6.9.3"
pkgdesc="Qt Interface Framework Generator Qt Interface Framework provides a way for you"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://github.com/qt/qtinterfaceframework/archive/refs/tags/v6.9.3.tar.gz"
)
sha256sums=(
  "ac02cb9019a06e3fbbd975ceb1dfbe2688729be63a82e68889d78663948daf0b"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
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
