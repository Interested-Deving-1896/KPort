#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-coap
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt Coap Library Constrained Application Protocol (CoAP) is a machine-to-machine

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-coap"
pkgver="6.10.2"
pkgdesc="Qt Coap Library Constrained Application Protocol (CoAP) is a machine-to-machine"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://github.com/qt/qtcoap/archive/refs/tags/v6.10.2.tar.gz"
)
sha256sums=(
  "787e88eeccae01ad2fe9e0854377b042b7e6556f2c660bba33158c2d9622a9c2"
)

depends=(
  "qt6-base-dev"
  "qt6-declarative-dev"
)

makedepends=(
  "cmake"
  "debhelper"
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
