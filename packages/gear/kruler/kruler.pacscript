#!/usr/bin/env bash
# KPort pacscript — gear/kruler
# Promoted from generated/ — review and test before merging to main
#
# screen ruler KRuler is a tool for measuring the size, in pixels, of items on

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kruler"
pkgver="26.04.1"
pkgdesc="screen ruler"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/applications/graphics/kruler/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kruler-26.04.1.tar.xz"
)
sha256sums=(
  "dcf9aaaf349950bd2f8339653c50c05166da74a19bb92de8f2a8e4e27eb2ebfb"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-ki18n"
  "kf6-knotifications"
  "kf6-kstatusnotifieritem"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kcrash"
  "kf6-kdoctools"
  "kf6-ki18n"
  "kf6-knotifications"
  "kf6-kstatusnotifieritem-dev"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "libx11-dev"
  "libxcb1-dev"
  "pkgconf"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+x11"
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
