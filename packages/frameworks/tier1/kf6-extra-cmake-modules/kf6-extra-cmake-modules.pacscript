#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-extra-cmake-modules
# Promoted from generated/ — review and test before merging to main
#
# Extra CMake modules

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-extra-cmake-modules"
pkgver="6.26.0"
pkgdesc="Extra CMake modules"
url="https://projects.kde.org/projects/kdesupport/extra-cmake-modules"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/extra-cmake-modules-6.26.0.tar.xz"
)
sha256sums=(
  "f4e10d9d45aafb5273e996196040f4e420f0bc4071c208282aae94d9ad8e1743"
)

depends=(
  "python3:any"
)

makedepends=(
  "cmake"
  "libjs-jquery"
  "libjs-underscore"
  "python3"
  "python3-distutils-extra"
  "python3-setuptools"
  "python3-sphinx"
  "python3-sphinxcontrib.qthelp"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
  "sphinx-common"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
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
