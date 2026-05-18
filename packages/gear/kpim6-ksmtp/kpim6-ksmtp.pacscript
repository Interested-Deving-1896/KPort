#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-ksmtp
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# library for handling SMTP data

pkgname="kpim6-ksmtp"
pkgver="26.04.1"
pkgdesc="library for handling SMTP data"
url="https://invent.kde.org/pim/ksmtp"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/ksmtp-26.04.1.tar.xz"
)
sha256sums=(
  "81bf1e19757671b1b69cb7790b422fe4814bfb13fac7264059201b032454c1f1"
)

depends=(
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "~apt:libc6"
  "~apt:libsasl2-2"
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
