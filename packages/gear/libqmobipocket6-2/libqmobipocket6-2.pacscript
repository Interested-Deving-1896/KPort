#!/usr/bin/env bash
# KPort pacscript — gear/libqmobipocket6-2
# Promoted from generated/ — review and test before merging to main
#
# library for reading Mobipocket documents QMobipocket is a Qt library for

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="libqmobipocket6-2"
pkgver="26.04.1"
pkgdesc="library for reading Mobipocket documents"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kdegraphics-mobipocket-26.04.1.tar.xz"
)
sha256sums=(
  "de353837314402f4983893226483a88a9026266b53ddf64b07ef234d149ff7bd"
)

depends=(
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-ki18n"
  "kf6-kio"
  "pkgconf"
  "qt6-base-dev"
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
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF) \
    -DBUILD_QCH=$(use_flag docs ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
