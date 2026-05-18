#!/usr/bin/env bash
# KPort pacscript — plasma/kwayland
# Promoted from generated/ — review and test before merging to main
#
# Qt-style API to interact with the wayland-client API

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kwayland"
pkgver="6.6.5"
pkgdesc="Qt-style API to interact with the wayland-client API"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/frameworks/kwayland"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kwayland-6.6.5.tar.xz"
)
sha256sums=(
  "afbcd53ca8a5fb501038415f1473c3d11556eb56ed8f653ece03f77d799cad01"
)

depends=(
  "libwayland-client0"
  "qt6-base"
  "qt6-wayland"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libegl1-mesa-dev"
  "libwayland-dev"
  "pkgconf"
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
KGPU_MIN="gpu-gl4"

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
