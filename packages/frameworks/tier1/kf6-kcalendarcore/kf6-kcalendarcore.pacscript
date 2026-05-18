#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kcalendarcore
# Promoted from generated/ — review and test before merging to main
#
# The KDE calendar access library

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcalendarcore"
pkgver="6.26.0"
pkgdesc="The KDE calendar access library"
url="https://projects.kde.org/projects/kde/pim/kcalcore"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcalendarcore-6.26.0.tar.xz"
)
sha256sums=(
  "386be0eee392d8432b6b7fafd3dead95dd1fc74f81790928c580f81e6222a17c"
)

depends=(
  "python3-pyside6.qtcore"
)

makedepends=(
  "bison"
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libclang-dev"
  "libpyside6-dev"
  "libpython3-dev"
  "libshiboken6-dev"
  "libical-dev"
  "llvm-dev"
  "python3-dev"
  "python3-build"
  "pyside6-tools"
  "qt6-base-dev"
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
