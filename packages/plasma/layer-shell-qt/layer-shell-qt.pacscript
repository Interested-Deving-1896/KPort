#!/usr/bin/env bash
# KPort pacscript — plasma/layer-shell-qt
# Promoted from generated/ — review and test before merging to main
#
# use the Wayland wl-layer-shell protocol

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="layer-shell-qt"
pkgver="6.6.5"
pkgdesc="use the Wayland wl-layer-shell protocol"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="http://www.kde.org/"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/layer-shell-qt-6.6.5.tar.xz"
)
sha256sums=(
  "e8c145545ac49d5325f16ff710b521deab6e5b9745fcc18ab431252224a8f982"
)

depends=(
  "liblayershellqtinterface6"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "libwayland-bin"
  "libwayland-dev"
  "libxkbcommon-dev"
  "pkgconf"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-wayland-dev"
  "qt6-wayland-dev-tools"
  "wayland-protocols"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+wayland"
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
