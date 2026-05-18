#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-baloo
# Promoted from generated/ — review and test before merging to main
#
# Baloo is a file indexing and searching framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-baloo"
pkgver="6.26.0"
pkgdesc="Baloo is a file indexing and searching framework"
url="https://projects.kde.org/projects/frameworks/baloo"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/baloo-6.26.0.tar.xz"
)
sha256sums=(
  "702f5b868aaef48153c6c3828111b3b335403079491a8f37043ebd89c6995b30"
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kidletime"
  "kf6-kio"
  "kf6-solid"
  "liblmdb0"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kauth-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kcrash-dev"
  "kf6-kdbusaddons-dev"
  "kf6-kfilemetadata-dev"
  "kf6-ki18n-dev"
  "kf6-kidletime-dev"
  "kf6-kio-dev"
  "kf6-solid-dev"
  "liblmdb-dev"
  "libxapian-dev"
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
