#!/usr/bin/env bash
# KPort pacscript — gear/kpim6-ktnef
# Promoted from generated/ — review and test before merging to main
#
# An API for handling TNEF data

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kpim6-ktnef"
pkgver="26.04.1"
pkgdesc="An API for handling TNEF data"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/pim/ktnef"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/ktnef-26.04.1.tar.xz"
)
sha256sums=(
  "1b5bd61c549ea306730ff6f7d2de43e0738b0d180a0b63148339b7df40225b2b"
)

depends=(
  "kf6-kcalendarcore"
  "kf6-kcontacts"
  "kf6-ki18n"
  "kpim6-kcalendarutils"
  "qt6-base"
).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "doxygen"
  "kf6-extra-cmake-modules"
  "kf6-kcalendarcore-dev"
  "kf6-kcontacts"
  "kpim6-kcalendarutils-dev"
  "libical-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
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
