#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-kirigami
# Promoted from generated/ — review and test before merging to main
#
# QtQuick plugins to build user interfaces based on the KDE human interface guidelines

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kirigami"
pkgver="6.26.0"
pkgdesc="QtQuick plugins to build user interfaces based on the"
url="https://cgit.kde.org/kirigami.git/"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kirigami-6.26.0.tar.xz"
)
sha256sums=(
  "b268785b271198acec7fe4b6177eafdee890e180245c7168916da3ccff1425ff"
)

depends=(
  "kf6-kdeclarative"
  "kf6-kitemmodels"
  "qt6-5compat-dev"
  "qt6-declarative-dev"
)

makedepends=(
  "kf6-breeze-icon-theme"
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "qt6-5compat-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-shadertools-dev"
  "qt6-svg-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
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
