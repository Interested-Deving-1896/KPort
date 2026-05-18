#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-phonon-backend-vlc
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# Qt6 Phonon VLC backend Phonon is the KF6 multimedia API, which provides a

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-phonon-backend-vlc"
pkgver="0.11.3"
pkgdesc="Qt6 Phonon VLC backend"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://invent.kde.org/libraries/phonon-vlc.git"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/phonon/phonon-backend-vlc/0.11.3/phonon-backend-vlc-0.11.3.tar.xz"
)
sha256sums=(
  "5e69fdeccb060c7e6b5924cef2e65bee5a08ace4127005b95344ed3077dc6397"
)

depends=(
  "vlc-plugin-base"
  "vlc-plugin-video-output"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "libphonon4qt6-dev"
  "libphonon4qt6experimental-dev"
  "libv4l-dev"
  "libvlc-dev"
  "libvlccore-dev"
  "libx11-dev"
  "pkg-config"
  "qt6-base-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
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
