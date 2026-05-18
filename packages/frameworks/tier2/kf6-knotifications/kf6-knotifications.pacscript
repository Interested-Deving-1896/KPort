#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-knotifications
# Promoted from generated/ — review and test before merging to main
#
# Abstraction for system notifications

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-knotifications"
pkgver="6.26.0"
pkgdesc="Abstraction for system notifications"
url="https://projects.kde.org/projects/frameworks/knotifications"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/knotifications-6.26.0.tar.xz"
)
sha256sums=(
  "2033a798856a9d2776e6e4cef6f3eb3bc24b938c0d00b06b2f6e71be44e1446a"
)

depends=(
  "python3-pyside6.qtcore"
)

makedepends=(
  "cmake"
  "dbus-x11"
  "dh-python"
  "dh-sequence-python3"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kcodecs-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kwindowsystem-dev"
  "libcanberra-dev"
  "libclang-dev"
  "libdbusmenu-qt6-dev"
  "libpyside6-dev"
  "libpython3-dev"
  "libshiboken6-dev"
  "pkgconf"
  "python3-dev"
  "python3-build"
  "qt6-base-dev"
  "qt6-base-private-dev"
  "qt6-tools-dev"
  "xauth"
  "xvfb"
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
