#!/usr/bin/env bash
# KPort pacscript — gear/okular
# Promoted from generated/ — reviewed and tested against KDE Neon Noble Numbat.
#
# Universal document viewer (app binary).
# The okular Debian source produces libokular6core4 (library) and okular (app)
# as separate binary packages from the same upstream tarball.

pkgname="okular"
pkgver="26.04.1"
pkgdesc="Universal document viewer"
url="https://apps.kde.org/okular/"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/okular-26.04.1.tar.xz"
)
sha256sums=(
  "3d87a0d9e9fe62435a913190a0a7edd75bec6a02ce2eda4089046adcffc6bba6"
)

depends=(
  "~apt:okular-backends"
  "kf6-karchive"
  "kf6-kbookmarks"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kparts"
  "kf6-ktextwidgets"
  "kf6-kwallet"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-purpose"
  "libokular6core4"
  "qt6-base"
  "qt6-phonon"
  "qt6-speech"
)

makedepends=(
  "cmake"
  "ninja-build"
  "kf6-extra-cmake-modules"
  "libokular6core4"
  "qt6-base-dev"
)

KCATEGORY="gear"
KSLOT="6"

build() {
  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=OFF

  cmake --build build --parallel "$(nproc)"
}

package() {
  DESTDIR="$pkgdir" cmake --install build
}
