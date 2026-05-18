#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-kidentitymanagement
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# library for managing user identities

pkgname="kpim6-kidentitymanagement"
pkgver="26.04.1"
pkgdesc="library for managing user identities"
url="https://invent.kde.org/pim/kidentitymanagement"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kidentitymanagement-26.04.1.tar.xz"
)
sha256sums=(
  "4e93a35a2bb34e47c9d27f90c70365d38ead10b334249946225abb91cbfe5590"
)

depends=(
  "kf6-kirigami"
  "~apt:qml6-module-org-kde-kirigamiaddons"
  "~apt:qml6-module-qt-labs-platform"
  "~apt:qml6-module-qtquick-controls"
  "kf6-kcodecs"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-ktextaddons"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kpim6-kpimtextedit"
  "qt6-base"
  "qt6-declarative"
)

makedepends=()

KCATEGORY="gear"
KSLOT="6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"
KUSE=(
  "-test"
)

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
