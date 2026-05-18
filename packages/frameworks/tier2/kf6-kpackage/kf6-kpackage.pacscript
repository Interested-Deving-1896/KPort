#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kpackage
# Promoted from generated/ — review and test before merging to main
#
# Library to load and install packages of non binary files as they were a plugin

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kpackage"
pkgver="6.26.0"
pkgdesc="Library to load and install packages of non binary files as they were a plugin"
url="https://projects.kde.org/projects/frameworks/kpackage"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kpackage-6.26.0.tar.xz"
)
sha256sums=(
  "313cda4a335ecdb67bb8e2fcc15bdeb5970db17d5597282ca655bf97a98abab5"
)

depends=(
  "kf6-karchive"
  "kf6-kcoreaddons"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-karchive-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kdoctools-dev"
  "kf6-ki18n-dev"
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
