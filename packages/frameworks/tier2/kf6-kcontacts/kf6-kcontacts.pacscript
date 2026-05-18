#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kcontacts
# Promoted from generated/ — review and test before merging to main
#
# API for address book data

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kcontacts"
pkgver="6.26.0"
pkgdesc="API for address book data"
url="https://projects.kde.org/projects/kde/pim/kcontacts"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kcontacts-6.26.0.tar.xz"
)
sha256sums=(
  "dce9af34050fcf09c8b4ece6df5a0abedbaf02fe85039fc371c5e11e91443cf0"
)

depends=(
  "kf6-kcodecs"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "doxygen"
  "kf6-extra-cmake-modules"
  "kf6-kcodecs-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-ki18n-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier2"
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
