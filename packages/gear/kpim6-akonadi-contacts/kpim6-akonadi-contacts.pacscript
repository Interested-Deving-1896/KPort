#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-akonadi-contacts
# Promoted from generated/ — review and test before merging to main
#
# Akonadi contacts access library - data files This library provides contacts

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kpim6-akonadi-contacts"
pkgver="26.04.1"
pkgdesc="Akonadi contacts access library - data files This library provides contacts"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://pim.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/akonadi-contacts-26.04.1.tar.xz"
)
sha256sums=(
  "e63ba2740584e6620e9175b4477ad68f5cbe0aa369580e208b4502c2c3daa120"
)

depends=(
  "kf6-kcodecs"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kcontacts"
  "kf6-kcoreaddons"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-ktextaddons"
  "kf6-ktexttemplate"
  "kf6-ktextwidgets"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "kf6-prison"
  "kpim6-akonadi"
  "kpim6-grantleetheme"
  "kpim6-kmime"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "kf6-extra-cmake-modules"
  "kf6-kcmutils"
  "kf6-kcodecs"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kcontacts"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-ktextaddons-dev"
  "kf6-ktexttemplate-dev"
  "kf6-ktextwidgets"
  "kf6-prison"
  "kpim6-akonadi-dev"
  "kpim6-akonadi-mime-dev"
  "kpim6-grantleetheme-dev"
  "kpim6-kmime-dev"
  "kpim6-libkleo-dev"
  "pkgconf"
  "qt6-base-dev"
  "qt6-base-doc"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"
  "-test"
)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  _kport_lib="${KPORT_LIB_DIR:-/usr/lib/kport}/use-helpers.sh"
  [[ -f "$_kport_lib" ]] && source "$_kport_lib"

  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF) \
    -DBUILD_QCH=$(use_flag docs ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
