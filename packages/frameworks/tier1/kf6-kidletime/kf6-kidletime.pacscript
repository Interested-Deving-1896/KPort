#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kidletime
# Promoted from generated/ — review and test before merging to main
#
# Monitoring user activity

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kidletime"
pkgver="6.26.0"
pkgdesc="Monitoring user activity"
url="https://projects.kde.org/kidletime"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kidletime-6.26.0.tar.xz"
)
sha256sums=(
  "f0efd67ee0e5b5eb9200e924e9478c1ecb179b4a38e0cf125b377e7fa373ef07"
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
  "libwayland-dev"
  "libx11-dev"
  "libx11-xcb-dev"
  "libxcb-sync-dev"
  "libxcb1-dev"
  "libxss-dev"
  "pkgconf"
  "plasma-wayland-protocols"
  "qt6-base-dev"
  "qt6-tools-dev"
  "qt6-wayland-dev"
  "wayland-protocols"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+wayland"
  "+x11"
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
