#!/usr/bin/env bash
# KPort pacscript — gear/bovo
# Promoted from generated/ — review and test before merging to main
#
# gomoku (five in line) board game Bovo is a game where two players take turns

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="bovo"
pkgver="26.04.1"
pkgdesc="gomoku (five in line) board game"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://games.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/bovo-26.04.1.tar.xz"
)
sha256sums=(
  "e55b788547ed250e417282d883d9d13246c8f475016f20c03f0ed2d6a58a2482"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "~apt:libkf6kdegames6-6"
  "qt6-base"
  "qt6-svg"
)

makedepends=(
  "7zip"
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "libkdegames6-dev"
  "kf6-kxmlgui"
  "qt6-svg-dev"
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
