#!/usr/bin/env bash
# KPort pacscript — plasma/kdecoration
# Library for creating window decorations (KDE Plasma 6).

pkgname="kdecoration"
pkgver="6.6.5"
pkgdesc="Plugin-based library to create window decorations"
url="https://invent.kde.org/plasma/kdecoration"
license=("LGPL-2.1-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kdecoration-6.6.5.tar.xz"
)
sha256sums=(
  "06e8ed04b8f3cdcd3057a9e2d23291ef41a3976f96fc8cf917479218871aa9fd"
)

depends=(
  "kf6-ki18n"
)

makedepends=(
  "cmake"
  "ninja-build"
  "kf6-extra-cmake-modules"
  "kf6-ki18n"
  "qt6-base-dev"
)

KCATEGORY="plasma"
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
