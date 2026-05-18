#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-kxmlgui
# Promoted from generated/ — review and test before merging to main
#
# User configurable main windows

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-kxmlgui"
pkgver="6.26.0"
pkgdesc="User configurable main windows"
url="https://projects.kde.org/projects/frameworks/kxmlgui"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/kxmlgui-6.26.0.tar.xz"
)
sha256sums=(
  "4383855cea5a7f9a269c72dda15490b8d70c1d23d17950963937332fc5d6b7a0"
)

depends=(
  "python3-pyside6.qtcore"
)

makedepends=(
  "cmake"
  "dh-python"
  "dh-sequence-python3"
  "doxygen"
  "graphviz"
  "kf6-attica-dev"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme-dev"
  "kf6-kconfig-dev"
  "kf6-kconfigwidgets-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kglobalaccel-dev"
  "kf6-kguiaddons-dev"
  "kf6-ki18n-dev"
  "kf6-kiconthemes-dev"
  "kf6-kitemviews-dev"
  "kf6-ktextwidgets-dev"
  "kf6-kwidgetsaddons-dev"
  "kf6-kwindowsystem-dev"
  "libclang-dev"
  "libcups2-dev"
  "libpyside6-dev"
  "libpython3-dev"
  "libshiboken6-dev"
  "python3-dev"
  "python3-build"
  "pyside6-tools"
  "qt6-base-dev"
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
