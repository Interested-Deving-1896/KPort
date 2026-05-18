#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kcolorscheme
# Promoted from generated/ — review and test before merging to main
#
# Classes to interact with KColorScheme

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcolorscheme"
pkgver="6.26.0"
pkgdesc="Classes to interact with KColorScheme"
url="https://invent.kde.org/frameworks/kcolorscheme"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcolorscheme-6.26.0.tar.xz"
)
sha256sums=(
  "74149a0379bd8bf6590d3c1f7f8c503665e0f3adafc2adbd44fc6bb764c969f1"
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
  "kf6-kguiaddons"
  "kf6-ki18n"
  "qt6-base-dev"
  "qt6-tools-dev"
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
