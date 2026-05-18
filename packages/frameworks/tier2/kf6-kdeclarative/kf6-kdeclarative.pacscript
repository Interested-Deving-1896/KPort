#!/usr/bin/env bash
# KPort pacscript — frameworks/tier2/kf6-kdeclarative
# Promoted from generated/ — review and test before merging to main
#
# Integration of QML and KDE Frameworks

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kdeclarative"
pkgver="6.26.0"
pkgdesc="Integration of QML and KDE Frameworks"
url="https://projects.kde.org/projects/frameworks/kdeclarative"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kdeclarative-6.26.0.tar.xz"
)
sha256sums=(
  "9a464e560e436cd3a626ca6aab894f414c6212d2de8b9c5a8eda33be213e00d8"
)

depends=(
  "kf6-kconfig"
  "kf6-kglobalaccel"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "doxygen"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme-dev"
  "kf6-kconfig-dev"
  "kf6-kglobalaccel-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kio-dev"
  "libepoxy-dev"
  "pkgconf"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-shadertools-dev"
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
