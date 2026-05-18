#!/usr/bin/env bash
# KPort pacscript — plasma/kmenuedit
# Promoted from generated/ — review and test before merging to main
#
# XDG menu editor This package provides a menu editor which may be used to edit

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kmenuedit"
pkgver="6.6.5"
pkgdesc="XDG menu editor"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/workspace/kmenuedit"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kmenuedit-6.6.5.tar.xz"
)
sha256sums=(
  "1c24f15e13d16ad9c0643ea2a0849420329fd10b62fd262b48cdade678274828"
)

depends=(
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-kglobalaccel"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kitemviews"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-sonnet"
  "qt6-base"
)

makedepends=(
  "cmake"
  "debhelper"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kitemmodels"
  "kf6-kxmlgui"
  "kf6-sonnet"
  "qt6-base-dev"
  "xauth"
  "xvfb"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
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
