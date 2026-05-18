#!/usr/bin/env bash
# KPort pacscript — gear/kwordquiz
# Promoted from generated/ — review and test before merging to main
#
# flashcard learning program KWordQuiz is a general purpose flashcard program,

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kwordquiz"
pkgver="26.04.1"
pkgdesc="flashcard learning program"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/kdeedu/kwordquiz"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kwordquiz-26.04.1.tar.xz"
)
sha256sums=(
  "e0e802a78ac5f410d3c16cdcd4f2fddbce26b40c6e2b9525aa324a1e7aa45dc9"
)

depends=(
  "~apt:kdeedu-kvtml-data"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-ki18n"
  "kf6-knewstuff"
  "~apt:libkeduvocdocument6"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kirigami-addons-dev"
  "kf6-kirigami"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdoctools"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kitemviews"
  "kf6-knewstuff"
  "kf6-knotifications"
  "kf6-knotifyconfig-dev"
  "kf6-kxmlgui"
  "libcups2-dev"
  "libkeduvocdocument-dev"
  "qt6-phonon-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-multimedia-dev"
  "qt6-svg-dev"
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
