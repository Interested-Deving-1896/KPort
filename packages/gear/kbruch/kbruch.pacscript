#!/usr/bin/env bash
# KPort pacscript — gear/kbruch
# Promoted from generated/ — review and test before merging to main
#
# fraction learning aid for KDE KBruch is an aid for learning how to calculate

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kbruch"
pkgver="26.04.1"
pkgdesc="fraction learning aid for KDE"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/projects/kde/kdeedu/kbruch"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kbruch-26.04.1.tar.xz"
)
sha256sums=(
  "82a592d6eb42e19d588844af131a3b6a4ec179656d48f91ae26d70ffe2205dab"
)

depends=(
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-ki18n"
  "kf6-kwidgetsaddons"
  "kf6-kxmlgui"
  "qt6-base"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kcrash"
  "kf6-kdoctools"
  "kf6-ki18n"
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
