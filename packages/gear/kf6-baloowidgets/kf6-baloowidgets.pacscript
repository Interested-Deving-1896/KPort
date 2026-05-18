#!/usr/bin/env bash
# KPort pacscript — gear/kf6-baloowidgets

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-baloowidgets"
pkgver="26.04.1"
pkgdesc="widgets for use with Baloo"
url="http://projects.kde.org/baloo-widgets"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/baloo-widgets-26.04.1.tar.xz"
)
sha256sums=(
  "687856a4390680ad1584ff2edf8d7eed5857be6a51ca485600b521bd82ebdcd0"
)

depends=(
  "kf6-baloo"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-baloo"
  "kf6-extra-cmake-modules"
  "kf6-kconfig"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kio"
  "~apt:pkgconf"
  "qt6-base"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
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
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
