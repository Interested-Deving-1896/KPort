#!/usr/bin/env bash
# KPort pacscript — gear/bomber
# Promoted from generated/ — review and test before merging to main
#
# arcade spaceship game Bomber is a game where you fly a spaceship and attempt to

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="bomber"
pkgver="26.04.1"
pkgdesc="arcade spaceship game"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://games.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/bomber-26.04.1.tar.xz"
)
sha256sums=(
  "3eaa234b497f1126ebf41b4ceeddbcda7d13d337c2f6e5d6680beb46df77906d"
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
)

makedepends=(
  "7zip"
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-ki18n"
  "libkdegames6-dev"
  "kf6-kxmlgui"
  "qt6-base-dev"
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
