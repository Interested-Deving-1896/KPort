#!/usr/bin/env bash
# KPort pacscript — qt6/qbs
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# cross-platform build tool Qbs is a general purpose cross-platform build tool

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qbs"
pkgver="3.0.1"
pkgdesc="cross-platform build tool Qbs is a general purpose cross-platform build tool"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://wiki.qt.io/Qbs"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qbs/3.0.1/qbs-src-3.0.1.tar.gz"
)
sha256sums=(
  "154838d4a0647ebe9fab80bad9a8f6057c08f5723b6b06638b37cfd96bfa70be"
)

depends=(
  "qbs-common"
)

makedepends=(
  "cmake"
  "debhelper"
  "dpkg-build-api"
  "ninja-build"
  "pkg-kde-tools"
  "python3-soupsieve"
  "python3-lxml"
  "qt6-5compat-dev"
  "qt6-base-dev"
  "qt6-base-private-dev"
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
