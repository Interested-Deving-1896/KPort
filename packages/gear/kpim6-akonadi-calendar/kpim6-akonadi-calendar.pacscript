#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-akonadi-calendar
# Promoted from generated/ — reviewed against KDE Neon Noble Numbat.
#
# Akonadi calendar library - runtime binaries

pkgname="kpim6-akonadi-calendar"
pkgver="26.04.1"
pkgdesc="Akonadi calendar library - runtime binaries"
url="https://invent.kde.org/pim/akonadi-calendar"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/akonadi-calendar-26.04.1.tar.xz"
)
sha256sums=(
  "789cae6c1c2c16b32a8f8f9a1eb9587a251058a071ee6eea66d016769a7505f7"
)

depends=(
  "kf6-kcalendarcore"
  "kf6-kcodecs"
  "kf6-kconfig"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kitemmodels"
  "kf6-knotifications"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kpim6-akonadi"
  "kpim6-akonadi-contacts"
  "kpim6-akonadi-mime"
  "kpim6-kcalendarutils"
  "kpim6-kidentitymanagement"
  "kpim6-kmailtransport"
  "kpim6-kmime"
  "kpim6-libkleo"
  "kpim6-messagelib"
  "~apt:libgpgmepp7"
  "~apt:libqgpgmeqt6-15"
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
