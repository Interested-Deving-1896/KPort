#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kguiaddons
# Promoted from generated/ — review and test before merging to main
#
# Addons to QtGui

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kguiaddons"
pkgver="6.26.0"
pkgdesc="Addons to QtGui"
url="https://projects.kde.org/kguiaddons"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kguiaddons-6.26.0.tar.xz"
)
sha256sums=(
  "8375342f852104f36fd72a6870eb9795183af4516592cd6fa73445ea6b813172"
)

depends=(
  "python3-pyside6.qtcore"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libclang-dev"
  "libpyside6-dev"
  "libpython3-dev"
  "libshiboken6-dev"
  "libwayland-dev"
  "libx11-dev"
  "libxcb1-dev"
  "pkgconf"
  "plasma-wayland-protocols"
  "python3-dev"
  "python3-build"
  "pyside6-tools"
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
