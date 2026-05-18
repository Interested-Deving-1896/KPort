#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kcoreaddons
# Promoted from generated/ — review and test before merging to main
#
# Addons to QtCore

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcoreaddons"
pkgver="6.26.0"
pkgdesc="Addons to QtCore"
url="https://projects.kde.org/kcoreaddons"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcoreaddons-6.26.0.tar.xz"
)
sha256sums=(
  "92fdbfab68e52d9eacf44a992f01cb364d6395c24441e2fd47dd48a23b3281f6"
)

depends=(
  "python3-pyside6.qtcore"
  "shared-mime-info"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "libclang-dev"
  "libpyside6-dev"
  "libpython3-dev"
  "libshiboken6-dev"
  "libudev-dev"
  "llvm-dev"
  "python3-dev"
  "python3-build"
  "pyside6-tools"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
  "shared-mime-info"
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
