#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-krunner
# Promoted from generated/ — review and test before merging to main
#
# Parallelized query system

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-krunner"
pkgver="6.26.0"
pkgdesc="Parallelized query system"
url="https://projects.kde.org/projects/frameworks/krunner"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/krunner-6.26.0.tar.xz"
)
sha256sums=(
  "3519c7fe170be1359a4c38dd5269de64c0208ccfeb950661002ddfa4e92f2bf0"
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
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kitemmodels-dev"
  "kf6-kwindowsystem-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
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
