#!/usr/bin/env bash
# KPort pacscript — overlays/example/frameworks/tier2/kf6-karchive
#
# Example overlay pacscript: shadows the main-tree kf6-karchive with an
# identical build but a patched pkgdesc to demonstrate overlay resolution.
# In a real overlay this would carry a patch, a git snapshot, or a backport.

pkgname="kf6-karchive"
pkgver="6.26.0"
pkgdesc="Qt 6 addon providing access to numerous types of archives (example overlay)"
url="https://projects.kde.org/projects/frameworks/karchive"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/karchive-6.26.0.tar.xz"
)
sha256sums=(
  "a7fdf6d0b8db88d60aa52bcc87d8e00d95391a1ad39a4b2a8e9f3027b8ff4035"
)

depends=(
  "qt6-base"
  "libb2-1"
  "libbz2-1.0"
  "liblzma5"
  "liblz4-1"
  "libzstd1"
  "zlib1g"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libbz2-dev"
  "liblzma-dev"
  "libzstd-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
  "zlib1g-dev"
)

KSLOT="6"
KCATEGORY="frameworks/tier2"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"
  "-test"
)

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

package() {
  DESTDIR="$pkgdir" cmake --install build
}
