#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kauth
# Promoted from generated/ — review and test before merging to main
#
# Abstraction to system policy and authentication features

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kauth"
pkgver="6.26.0"
pkgdesc="Abstraction to system policy and authentication features"
url="https://projects.kde.org/projects/frameworks/kauth"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kauth-6.26.0.tar.xz"
)
sha256sums=(
  "e6b6562114c2cb71db6ca48fdf0ebed2df70e164c48295b35433a80b03385847"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kcoreaddons-dev"
  "kf6-kwindowsystem-dev"
  "libpolkit-qt6-1-dev"
  "pkgconf"
  "qt6-base-dev"
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
