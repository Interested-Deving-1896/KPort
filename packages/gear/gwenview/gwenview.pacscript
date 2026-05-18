#!/usr/bin/env bash
# KPort pacscript — gear/gwenview
# Promoted from generated/ — review and test before merging to main
#
# image viewer Gwenview is an image viewer, ideal for browsing and displaying a

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="gwenview"
pkgver="26.04.1"
pkgdesc="image viewer"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/gwenview-26.04.1.tar.xz"
)
sha256sums=(
  "47c8d6d97c1ec3c6e8138df4b233f7e1f7ebc86d3b04bf0b43196dea430a03bd"
)

depends=(
  "kf6-baloo"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kfilemetadata"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kitemmodels"
  "kf6-kitemviews"
  "kf6-kjobwidgets"
  "kf6-kparts"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kf6-purpose"
  "kf6-solid"
  "~apt:libcfitsio10t64"
  "~apt:libexiv2-27"
  "~apt:libjpeg8"
  "libkdcraw"
  "~apt:libkimageannotator-qt6-0"
  "~apt:liblcms2-2"
  "~apt:libpng16-16t64"
  "~apt:libtiff6"
  "~apt:libwayland-client0"
  "~apt:libx11-6"
  "kf6-kactivities"
  "qt6-base"
  "qt6-multimedia"
  "qt6-svg"
)

makedepends=(
  "cmake"
  "kf6-baloo-dev"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kdoctools"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kitemmodels"
  "kf6-knotifications"
  "kf6-kparts"
  "kf6-kwindowsystem"
  "kf6-purpose-dev"
  "libcfitsio-dev"
  "libexiv2-dev"
  "libjpeg-dev"
  "libkdcraw-dev"
  "libkimageannotator-qt6-dev"
  "liblcms2-dev"
  "libpng-dev"
  "libtiff-dev"
  "libwayland-dev"
  "pkgconf"
  "plasma-activities-dev"
  "qt6-base-dev"
  "qt6-multimedia-dev"
  "qt6-phonon-dev"
  "qt6-svg-dev"
  "qt6-wayland-dev"
  "wayland-protocols"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+wayland"
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
