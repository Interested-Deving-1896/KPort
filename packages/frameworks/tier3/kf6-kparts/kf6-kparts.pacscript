#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kparts
# Promoted from generated/ — review and test before merging to main
#
# Document centric plugin system

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kparts"
pkgver="6.26.0"
pkgdesc="Document centric plugin system"
url="https://projects.kde.org/projects/frameworks/kparts"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kparts-6.26.0.tar.xz"
)
sha256sums=(
  "049c2cf048b4cbbffe0bea9357bd9ab53b8be672ba509b2bb058f764d21b3f5b"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kbookmarks-dev"
  "kf6-kcolorscheme-dev"
  "kf6-kcompletion-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kio-dev"
  "kf6-kitemviews-dev"
  "kf6-kjobwidgets-dev"
  "kf6-knotifications-dev"
  "kf6-kservice-dev"
  "kf6-ktextwidgets-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kxmlgui-dev"
  "kf6-solid-dev"
  "kf6-sonnet-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
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
