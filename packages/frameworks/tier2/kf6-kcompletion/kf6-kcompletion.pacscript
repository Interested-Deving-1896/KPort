#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kcompletion
# Promoted from generated/ — review and test before merging to main
#
# Text completion helpers and widgets

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcompletion"
pkgver="6.26.0"
pkgdesc="Text completion helpers and widgets"
url="https://projects.kde.org/projects/frameworks/kcompletion"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcompletion-6.26.0.tar.xz"
)
sha256sums=(
  "95f71eb807e4de40ecdfe7234c9c3d844423171ac52588aecca642f78d904e48"
)

depends=(
  "kf6-kcodecs"
  "kf6-kconfig"
  "kf6-kwidgetsaddons"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kcodecs-dev"
  "kf6-kconfig-dev"
  "kf6-kwidgetsaddons-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier2"
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
