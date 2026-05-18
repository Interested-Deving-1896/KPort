#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kded
# Promoted from generated/ — review and test before merging to main
#
# Extensible daemon for providing system level services

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kded"
pkgver="6.26.0"
pkgdesc="Extensible daemon for providing system level services"
url="https://projects.kde.org/projects/frameworks/kded"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kded-6.26.0.tar.xz"
)
sha256sums=(
  "4265d1162cbd7febf16d103bf1bd9fab858fa3f54f52797ed0938436bee347af"
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kservice"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kcrash-dev"
  "kf6-kdbusaddons-dev"
  "kf6-kdoctools-dev"
  "kf6-kservice-dev"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
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
