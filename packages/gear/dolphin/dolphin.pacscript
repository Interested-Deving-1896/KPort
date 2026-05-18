#!/usr/bin/env bash
# KPort pacscript — gear/dolphin
# Promoted from generated/ — review and test before merging to main
#
# file manager Dolphin is the default file manager in the Plasma, intended to be

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="dolphin"
pkgver="26.04.1"
pkgdesc="file manager"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/dolphin-26.04.1.tar.xz"
)
sha256sums=(
  "ba4da5192f7e45f392feaa74dfb18fddddcf9dbcc8f9abeb3f670e83ed9e4f57"
)

depends=(
  "kf6-baloo"
  "kf6-baloowidgets"
  "kf6-kbookmarks"
  "kf6-kcmutils"
  "kf6-kcodecs"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kfilemetadata"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kjobwidgets"
  "kf6-knewstuff"
  "kf6-knotifications"
  "kf6-kparts"
  "kf6-kservice"
  "kf6-ktextwidgets"
  "kf6-kuserfeedback"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-solid"
  "~apt:libdolphinvcs6"
  "~apt:libpackagekitqt6"
  "qt6-base"
  "qt6-multimedia"
)

makedepends=(
  "cmake"
  "kf6-baloo-dev"
  "kf6-baloowidgets-dev"
  "kf6-extra-cmake-modules"
  "kf6-kbookmarks"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kcmutils"
  "kf6-kio"
  "kf6-knewstuff"
  "kf6-knotifications"
  "kf6-kparts"
  "kf6-solid"
  "kf6-ktextwidgets"
  "kf6-kuserfeedback-dev"
  "kf6-kwindowsystem"
  "libpackagekitqt6-dev"
  "pkgconf"
  "plasma-activities-dev"
  "qt6-base-dev"
  "qt6-multimedia-dev"
  "qt6-phonon-dev"
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
