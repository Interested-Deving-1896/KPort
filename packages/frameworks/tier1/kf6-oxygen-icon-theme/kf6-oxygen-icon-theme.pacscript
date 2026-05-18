#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-oxygen-icon-theme
# Promoted from generated/ — review and test before merging to main
#
# Oxygen icon theme Oxygen was the standard icon theme for KDE 4, but follows the

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-oxygen-icon-theme"
pkgver="6.1.0"
pkgdesc="Oxygen icon theme"
url="http://www.kde.org/"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/oxygen-icons/oxygen-icons-6.1.0.tar.xz"
)
sha256sums=(
  "16ca971079c5067c4507cabf1b619dc87dd6b326fd5c2dd9f5d43810f2174d68"
)

depends=(
  "hicolor-icon-theme"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "fdupes"
  "imagemagick"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
KNEON_CHANNEL="unstable"
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
