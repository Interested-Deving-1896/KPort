#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kconfig
# Promoted from generated/ — review and test before merging to main
#
# Configuration system

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kconfig"
pkgver="6.26.0"
pkgdesc="Configuration system"
url="https://projects.kde.org/projects/frameworks/kconfig"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kconfig-6.26.0.tar.xz"
)
sha256sums=(
  "8bb5aa918d8e60ec140a33db3c329414d2319dc97a1644b368da5576125c92b5"
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
  "libxkbcommon-dev"
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
