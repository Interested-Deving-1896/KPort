#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-knotifyconfig
# Promoted from generated/ — review and test before merging to main
#
# Configuration system for KNotify

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-knotifyconfig"
pkgver="6.26.0"
pkgdesc="Configuration system for KNotify"
url="https://projects.kde.org/projects/frameworks/knotifyconfig"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/knotifyconfig-6.26.0.tar.xz"
)
sha256sums=(
  "062e22f48a1da485d42ef56b37db1fc502f5f9305871483627d218f357560a28"
)

depends=(
  "kf6-kconfig"
  "kf6-ki18n"
  "kf6-kio"
  "libcanberra0"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kbookmarks-dev"
  "kf6-kcompletion-dev"
  "kf6-kconfig-dev"
  "kf6-kconfigwidgets-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kio-dev"
  "kf6-kjobwidgets-dev"
  "kf6-knotifications-dev"
  "kf6-kservice-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kxmlgui-dev"
  "kf6-solid-dev"
  "libcanberra-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
  "qt6-phonon-dev"
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
