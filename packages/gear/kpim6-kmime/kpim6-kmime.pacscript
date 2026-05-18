#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-kmime
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# library for handling MIME data

pkgname="kpim6-kmime"
pkgver="26.04.1"
pkgdesc="library for handling MIME data"
url="https://invent.kde.org/pim/kmime"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kmime-26.04.1.tar.xz"
)
sha256sums=(
  "79616a7bc28710f8f2fc4e7eee53342e83c58969eef09ba70e63ee2017472e6a"
)

depends=(
  "kf6-kcodecs"
  "~apt:libc6"
  "~apt:libgcc-s1"
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
