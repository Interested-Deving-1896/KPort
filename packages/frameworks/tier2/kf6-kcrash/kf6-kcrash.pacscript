#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kcrash
# Promoted from generated/ — review and test before merging to main
#
# Support for application crash analysis and bug report from apps

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcrash"
pkgver="6.26.0"
pkgdesc="Support for application crash analysis and bug report from apps"
url="https://projects.kde.org/projects/frameworks/kcrash"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcrash-6.26.0.tar.xz"
)
sha256sums=(
  "d05d93863a745ce0d4ab8ccff684a84a813ee4cbcc68c9c7a5175107b107e931"
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
  "kf6-kcoreaddons-dev"
  "kf6-kwindowsystem-dev"
  "libx11-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier2"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+x11"
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
