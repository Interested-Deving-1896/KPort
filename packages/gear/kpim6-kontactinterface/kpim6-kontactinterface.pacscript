#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-kontactinterface
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# Kontact interface library

pkgname="kpim6-kontactinterface"
pkgver="26.04.1"
pkgdesc="Kontact interface library"
url="https://invent.kde.org/pim/kontactinterface"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kontactinterface-26.04.1.tar.xz"
)
sha256sums=(
  "aecc871809676d6a70f963a80e8b75f31e527f6533e6b5a6b9c409b29d0a1ab5"
)

depends=(
  "kf6-kcoreaddons"
  "kf6-kio"
  "kf6-kparts"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "qt6-base"
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
