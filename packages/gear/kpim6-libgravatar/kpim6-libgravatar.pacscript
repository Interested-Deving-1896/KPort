#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-libgravatar
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# KDE PIM gravatar library

pkgname="kpim6-libgravatar"
pkgver="26.04.1"
pkgdesc="KDE PIM gravatar library"
url="https://invent.kde.org/pim/libgravatar"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/libgravatar-26.04.1.tar.xz"
)
sha256sums=(
  "09e468307448e8d77b0d94ce6defd2a2e61acc476ca6f294ba05da76c16d95c6"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "qt6-base"
)

makedepends=()

KCATEGORY="gear"
KSLOT="6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

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
