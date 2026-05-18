#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-ktextwidgets
# Promoted from generated/ — review and test before merging to main
#
# Advanced text editing widgets

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-ktextwidgets"
pkgver="6.26.0"
pkgdesc="Advanced text editing widgets"
url="https://projects.kde.org/projects/frameworks/ktextwidgets"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/ktextwidgets-6.26.0.tar.xz"
)
sha256sums=(
  "6511f9909f90fac951e2873a44dd451b8ac71d38085a62c65a6fb5028e62d84d"
)

depends=(
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "kf6-sonnet"
  "qt6-base"
  "qt6-speech"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kauth-dev"
  "kf6-kcodecs-dev"
  "kf6-kcolorscheme-dev"
  "kf6-kcompletion-dev"
  "kf6-kconfig-dev"
  "kf6-kconfigwidgets-dev"
  "kf6-kcoreaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kitemviews-dev"
  "kf6-kservice-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kwindowsystem-dev"
  "kf6-sonnet-dev"
  "qt6-base-dev"
  "qt6-multimedia-dev"
  "qt6-speech-dev"
  "qt6-tools-dev"
  "qt6-tools-private-dev"
  "xauth"
  "xvfb"
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
