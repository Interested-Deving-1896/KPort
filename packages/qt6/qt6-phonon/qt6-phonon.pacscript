#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-phonon
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# multimedia framework from KDE using Qt - core library Phonon is a Qt multimedia

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-phonon"
pkgver="4.11.1"
pkgdesc="multimedia framework from KDE using Qt - core library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://invent.kde.org/frameworks/qt6-phonon"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/phonon/4.11.1/phonon-4.11.1.tar.xz"
)
sha256sums=(
  "b4431ea2600df8137a717741ad9ebc7f7ec1649fa3e138541d8f42597144de2d"
)

depends=(
  "libpulse-mainloop-glib0"
  "libpulse0"
  "libqt5core5a"
  "libqt5gui5"
  "libqt5widgets5"
  "qt5-phonon"
  "qt6-5compat"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "libglib2.0-dev"
  "libpulse-dev"
  "qt6-5compat-dev"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl2"

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
