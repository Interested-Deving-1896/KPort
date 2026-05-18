#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-akonadi
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# Akonadi core library

pkgname="kpim6-akonadi"
pkgver="26.04.1"
pkgdesc="Akonadi core library"
url="https://invent.kde.org/pim/akonadi"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/akonadi-26.04.1.tar.xz"
)
sha256sums=(
  "135e671bfbf4209f4aa7f019738ccbb7d46745096ac833c042b502f1e5b5453a"
)

depends=(
  "kf6-kirigami"
  "kf6-kirigami-addons"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kitemmodels"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "~apt:liblzma5"
  "~apt:libxml2"
  "qt6-base"
  "qt6-declarative"
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
