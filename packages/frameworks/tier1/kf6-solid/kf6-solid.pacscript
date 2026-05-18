#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-solid
# Promoted from generated/ — review and test before merging to main
#
# Hardware integration and detection

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-solid"
pkgver="6.26.0"
pkgdesc="Hardware integration and detection"
url="https://projects.kde.org/projects/frameworks/solid"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/solid-6.26.0.tar.xz"
)
sha256sums=(
  "85cfab9b0787f59478661140997c485fadab62cec535ffcef2953d312f736c4a"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "bison"
  "cmake"
  "doxygen"
  "flex"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libimobiledevice-dev"
  "libmount-dev"
  "libudev-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
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
