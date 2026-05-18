#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-kcalendarutils
# Promoted from generated/ — review and test before merging to main
#
# The KDE calendar utility library

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kpim6-kcalendarutils"
pkgver="26.04.1"
pkgdesc="The KDE calendar utility library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/pim/kcalutils"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kcalutils-26.04.1.tar.xz"
)
sha256sums=(
  "bf5492583f4e56f7c1a98e32315e50def4df01daa5b5de12812d85150c7c7725"
)

depends=(
  "kf6-kcalendarcore"
  "kf6-kcodecs"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-ktexttemplate"
  "kf6-kwidgetsaddons"
  "kpim6-kidentitymanagement"
  "qt6-base"
)

makedepends=(
  "cmake"
  "doxygen"
  "kf6-extra-cmake-modules"
  "kf6-kcalendarcore-dev"
  "kf6-kcodecs"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-ktextaddons-dev"
  "kf6-ktexttemplate-dev"
  "kpim6-kidentitymanagement-dev"
  "kpim6-kpimtextedit-dev"
  "libical-dev"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
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
