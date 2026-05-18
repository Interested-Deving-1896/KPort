#!/usr/bin/env bash
# KPort pacscript — gear/ark
# Promoted from generated/ — review and test before merging to main
#
# archive utility Ark manages various archive formats, including tar, gzip,

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="ark"
pkgver="26.04.1"
pkgdesc="archive utility"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/ark-26.04.1.tar.xz"
)
sha256sums=(
  "e355434eb5d50499902cdb2a7120f5d5299feedaaad5f49d629436e55a668c71"
)

depends=(
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kjobwidgets"
  "kf6-kparts"
  "kf6-kpty"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "~apt:libarchive13t64"
  "~apt:libzip4t64"
  "qt6-base"
  "~apt:zlib1g"
)

makedepends=(
  "cmake"
  "gettext"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-kfilemetadata"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kitemmodels"
  "kf6-kio"
  "kf6-kparts"
  "kf6-kpty"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "libarchive-dev"
  "libbz2-dev"
  "liblzma-dev"
  "libzip5-dev"
  "pkgconf"
  "qt6-base-dev"
  "zlib1g-dev"
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
