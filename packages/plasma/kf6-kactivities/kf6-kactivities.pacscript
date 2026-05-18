#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-kactivities
# Promoted from generated/ — review and test before merging to main
#
# Activities Libary

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kactivities"
pkgver="6.6.5"
pkgdesc="Activities Libary"
url="https://projects.kde.org/projects/frameworks/kactivities"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/plasma-activities-6.6.5.tar.xz"
)
sha256sums=(
  "54d06a22a5765aa1e92834885d02abc7ce1bf8d6bda9533bb3472d4fef575562"
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kwindowsystem"
  "libboost-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
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
