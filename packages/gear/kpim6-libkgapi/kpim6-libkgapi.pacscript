#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-libkgapi
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# core library to integrate with Google service APIs

pkgname="kpim6-libkgapi"
pkgver="26.04.1"
pkgdesc="core library to integrate with Google service APIs"
url="https://invent.kde.org/pim/libkgapi"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/libkgapi-26.04.1.tar.xz"
)
sha256sums=(
  "f6f456f6cd90d7a5f1bc2c7c49a5813119d96263ca3b337e6c6e693bc6040270"
)

depends=(
  "~apt:qml6-module-sso-onlineaccounts"
  "qt6-webengine"
  "kf6-kcalendarcore"
  "kf6-kcontacts"
  "kf6-kwallet"
  "~apt:libc6"
  "~apt:libstdc++6"
  "qt6-base"
)

makedepends=()

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
