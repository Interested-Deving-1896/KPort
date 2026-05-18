#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kglobalaccel
# Promoted from generated/ — review and test before merging to main
#
# Add support for global workspace shortcuts

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kglobalaccel"
pkgver="6.26.0"
pkgdesc="Add support for global workspace shortcuts"
url="https://projects.kde.org/projects/frameworks/kglobalaccel"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kglobalaccel-6.26.0.tar.xz"
)
sha256sums=(
  "3f19d22d143577e5ddcc883170fe19a56f8f65766e41c4f9c011c4dfbde17a61"
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
  "kf6-ki18n-dev"
  "libx11-dev"
  "libxcb1-dev"
  "pkgconf"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
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
