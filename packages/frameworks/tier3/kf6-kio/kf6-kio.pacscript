#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kio
# Promoted from generated/ — review and test before merging to main
#
# Resource and network access abstraction

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kio"
pkgver="6.26.0"
pkgdesc="Resource and network access abstraction"
url="https://projects.kde.org/projects/frameworks/kio"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kio-6.26.0.tar.xz"
)
sha256sums=(
  "567f64db9766986b5535d884a5db30203685c33e67f56892bceff30e1bd5cc8a"
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
  "kf6-karchive-dev"
  "kf6-kauth-dev"
  "kf6-kbookmarks-dev"
  "kf6-kcolorscheme-dev"
  "kf6-kcompletion-dev"
  "kf6-kconfig-dev"
  "kf6-kconfigwidgets-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kcrash-dev"
  "kf6-kdbusaddons-dev"
  "kf6-kded-dev"
  "kf6-kdoctools-dev"
  "kf6-kguiaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kitemviews-dev"
  "kf6-kjobwidgets-dev"
  "kf6-kservice-dev"
  "kf6-ktextwidgets-dev"
  "kf6-kwallet-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kwindowsystem-dev"
  "kf6-kxmlgui-dev"
  "kf6-solid-dev"
  "kf6-sonnet-dev"
  "libacl1-dev"
  "libkrb5-dev"
  "libmount-dev"
  "libxml2-dev"
  "libxslt1-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
  "switcheroo-control"
  "zlib1g-dev"
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
