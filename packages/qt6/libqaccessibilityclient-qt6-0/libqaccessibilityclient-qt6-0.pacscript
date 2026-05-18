#!/usr/bin/env bash
# KPort pacscript — qt6/libqaccessibilityclient-qt6-0
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# helper to make writing accessibility tools easier Helper library to make

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="libqaccessibilityclient-qt6-0"
pkgver="0.6.0"
pkgdesc="helper to make writing accessibility tools easier Helper library to make"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://phabricator.kde.org/source/libqaccessibilityclient"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/libqaccessibilityclient/libqaccessibilityclient-0.6.0.tar.xz"
)
sha256sums=(
  "4c50c448622dc9c5041ed10da7d87b3e4e71ccb49d4831a849211d423c5f5d33"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "pkg-kde-tools"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
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
