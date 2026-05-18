#!/usr/bin/env bash
# KPort pacscript — plasma/kgamma
# Promoted from generated/ — review and test before merging to main
#
# monitor calibration panel for KDE This package contains a settings panel for

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kgamma"
pkgver="6.6.5"
pkgdesc="monitor calibration panel for KDE"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="http://www.kde.org/"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kgamma-6.6.5.tar.xz"
)
sha256sums=(
  "fab70445c88c98ce907e896d8c71cbf7771044880b5ef116fee969863e53360a"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "debhelper"
  "kf6-extra-cmake-modules"
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kdoctools"
  "kf6-ki18n"
  "libx11-dev"
  "libxxf86vm-dev"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+x11"
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
