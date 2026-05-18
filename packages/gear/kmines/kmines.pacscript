#!/usr/bin/env bash
# KPort pacscript — gear/kmines
# Promoted from generated/ — review and test before merging to main
#
# minesweeper game KMines is a game where the player finds hidden mines without

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kmines"
pkgver="26.04.1"
pkgdesc="minesweeper game"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://games.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kmines-26.04.1.tar.xz"
)
sha256sums=(
  "cf4a9826323620ae60998c2425b555a3b4d8fd8b4e1605bbaeb0ab3d99facd6a"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-ktextwidgets"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "~apt:libkf6kdegames6-6"
  "qt6-base"
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
  "kf6-ki18n"
  "libkdegames6-dev"
  "kf6-ktextwidgets"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kf6-sonnet"
  "qt6-base-dev"
  "qt6-declarative-dev"
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
