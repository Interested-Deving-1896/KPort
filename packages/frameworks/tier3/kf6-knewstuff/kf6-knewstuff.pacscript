#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-knewstuff
# Promoted from generated/ — review and test before merging to main
#
# Support for downloading application assets from the network

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-knewstuff"
pkgver="6.26.0"
pkgdesc="Support for downloading application assets from the network"
url="https://projects.kde.org/projects/frameworks/knewstuff"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/knewstuff-6.26.0.tar.xz"
)
sha256sums=(
  "94ef39077ba53a72f4e555b6f94a2762cba79730619cb80a31c5435642ebe1aa"
)

depends=(
  "kf6-kcmutils"
  "kf6-kirigami"
  "qt6-5compat"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-attica-dev"
  "kf6-extra-cmake-modules"
  "kf6-karchive-dev"
  "kf6-kbookmarks-dev"
  "kf6-kcompletion-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kio-dev"
  "kf6-kirigami2-dev"
  "kf6-kitemviews-dev"
  "kf6-kjobwidgets-dev"
  "kf6-kpackage-dev"
  "kf6-kservice-dev"
  "kf6-ktextwidgets-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kxmlgui-dev"
  "kf6-solid-dev"
  "kf6-syndication-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
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
