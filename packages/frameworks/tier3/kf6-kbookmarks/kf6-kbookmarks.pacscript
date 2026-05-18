#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kbookmarks
# Promoted from generated/ — review and test before merging to main
#
# Support for bookmarks and the XBEL format

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kbookmarks"
pkgver="6.26.0"
pkgdesc="Support for bookmarks and the XBEL format"
url="https://projects.kde.org/projects/frameworks/kbookmarks"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kbookmarks-6.26.0.tar.xz"
)
sha256sums=(
  "82e8794281870686da9e7e7b5ddc0839f50b15d919357490d508faccb2635030"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kwidgetsaddons"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme-dev"
  "kf6-kconfig-dev"
  "kf6-kconfigwidgets-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kwindowsystem-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
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
