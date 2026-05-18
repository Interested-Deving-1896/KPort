#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-kldap
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# library for accessing LDAP

pkgname="kpim6-kldap"
pkgver="26.04.1"
pkgdesc="library for accessing LDAP"
url="https://invent.kde.org/pim/kldap"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kldap-26.04.1.tar.xz"
)
sha256sums=(
  "4a63ce62cbb12d9c0dfc7502f1f83cf79296e2ee6785ba283e7872c527c3dc59"
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "~apt:libldap2"
  "~apt:libqt6keychain1"
  "~apt:libsasl2-2"
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
