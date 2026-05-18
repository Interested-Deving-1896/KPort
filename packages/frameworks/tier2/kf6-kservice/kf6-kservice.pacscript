#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kservice
# Promoted from generated/ — review and test before merging to main
#
# Library for querying installed applications and their associated file types

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kservice"
pkgver="6.26.0"
pkgdesc="Library for querying installed applications and their associated file types"
url="https://projects.kde.org/projects/frameworks/kservice"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kservice-6.26.0.tar.xz"
)
sha256sums=(
  "f8528524ccafb6a495962dd3260c442377920169f1c444f11657ea42558a53b6"
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "qt6-base"
)

makedepends=(
  "bison"
  "cmake"
  "dbus-x11"
  "docbook-xml"
  "docbook-xsl"
  "doxygen"
  "flex"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kcrash-dev"
  "kf6-kdbusaddons-dev"
  "kf6-kdoctools-dev"
  "kf6-ki18n-dev"
  "libxml2-utils"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier2"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"
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
