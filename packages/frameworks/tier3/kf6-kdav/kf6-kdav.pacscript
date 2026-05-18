#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kdav
# Promoted from generated/ — review and test before merging to main
#
# DAV protocol implementation with KJobs - arch independent files A DAV protocol

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kdav"
pkgver="6.26.0"
pkgdesc="DAV protocol implementation with KJobs - arch independent files A DAV protocol"
url="http://pim.kde.org/"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kdav-6.26.0.tar.xz"
)
sha256sums=(
  "7535b2b9a6eb35e5b539de780f2d2b84668eb97eec3b7a6cf14d91fbe6bedfec"
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
  "kf6-kio-dev"
  "kf6-kwidgetsaddons-dev"
  "qt6-base-dev"
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
