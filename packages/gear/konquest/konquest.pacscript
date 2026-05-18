#!/usr/bin/env bash
# KPort pacscript — gear/konquest
# Promoted from generated/ — review and test before merging to main
#
# simple turn-based strategy game Konquest is a game of galactic conquest for

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="konquest"
pkgver="26.04.1"
pkgdesc="simple turn-based strategy game"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://games.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/konquest-26.04.1.tar.xz"
)
sha256sums=(
  "b9b683c177e1d0da1ec966281800970ada1efb84cc3d7d3405cba5d88fa1c8aa"
)

depends=(
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "~apt:libkf6kdegames6-6"
  "qt6-base"
  "qt6-scxml"
  "qt6-svg"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "libkdegames6-dev"
  "qt6-base-dev"
  "qt6-scxml-dev"
  "qt6-svg-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
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
