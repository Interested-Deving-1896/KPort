#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-akonadi-search
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# Akonadi search library - data files

pkgname="kpim6-akonadi-search"
pkgver="26.04.1"
pkgdesc="Akonadi search library - data files"
url="https://invent.kde.org/pim/akonadi-search"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/akonadi-search-26.04.1.tar.xz"
)
sha256sums=(
  "2a3a40284faeb61c2d2f1b09ecc80c1844e498115ad8bccc1729431141b95e3f"
)

depends=(
  "kf6-kcalendarcore"
  "kf6-kcmutils"
  "kf6-kcodecs"
  "kf6-kconfig"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-krunner"
  "kf6-ktextaddons"
  "kf6-kwidgetsaddons"
  "kpim6-akonadi"
  "kpim6-akonadi-mime"
  "kpim6-kmime"
  "~apt:libxapian30"
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
