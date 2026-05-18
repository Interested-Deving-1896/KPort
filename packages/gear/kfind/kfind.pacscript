#!/usr/bin/env bash
# KPort pacscript — gear/kfind
# Promoted from generated/ — review and test before merging to main
#
# file search utility KFind can be used to find files and directories on your

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kfind"
pkgver="26.04.1"
pkgdesc="file search utility"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="http://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kfind-26.04.1.tar.xz"
)
sha256sums=(
  "f26fccc4652e593dcc70d688f042a4975193b955362ff7c2144208cb1130980d"
)

depends=(
  "kf6-karchive"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "qt6-5compat"
  "qt6-base"
).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kcoreaddons"
  "kf6-kconfigwidgets"
  "kf6-kcolorscheme"
  "kf6-kdoctools"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="gear"
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
