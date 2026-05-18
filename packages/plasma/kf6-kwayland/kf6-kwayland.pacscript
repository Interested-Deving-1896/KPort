#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-kwayland
# Promoted from generated/ — review and test before merging to main
#
# Qt-style API to interact with the wayland-client API

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kwayland"
pkgver="6.4.3"
pkgdesc="Qt-style API to interact with the wayland-client API"
url="https://projects.kde.org/projects/kde/frameworks/kwayland"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.4.3/kwayland-6.4.3.tar.xz"
)
sha256sums=(
  "ff507d3c435407b3831ead1ea63f6dea6c778ba6a1f5b45895d5fec6f5c1f982"
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
  "libegl1-mesa-dev"
  "libwayland-dev"
  "pkg-config"
  "plasma-wayland-protocols"
  "qt6-base-dev"
  "qt6-tools-dev"
  "qt6-wayland-dev"
  "wayland-protocols"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl2"

KUSE=(
  "+wayland"
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
