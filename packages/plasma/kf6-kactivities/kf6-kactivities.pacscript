#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-kactivities
# Promoted from generated/ — review and test before merging to main
#
# Activities Libary

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kactivities"
pkgver="6.4.3"
pkgdesc="Activities Libary"
url="https://projects.kde.org/projects/frameworks/kactivities"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.4.3/plasma-activities-6.4.3.tar.xz"
)
sha256sums=(
  "1c8dca746602defacd495b9ae637c1700d3be7e7e3cc5d499a5fd669a0b98ef0"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
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
