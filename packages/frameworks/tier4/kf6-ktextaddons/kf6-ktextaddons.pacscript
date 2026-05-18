#!/usr/bin/env bash
# KPort pacscript — frameworks/tier4/kf6-ktextaddons
# Promoted from generated/ — review and test before merging to main
#
# Text addons (autocorrection, text to speak, grammar checking, text translator, emoticon support, custom editor, autogenerate text)

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-ktextaddons"
pkgver="2.0.1"
pkgdesc="Text addons (autocorrection, text to speak, grammar checking, text translator"
url="https://invent.kde.org/libraries/ktextaddons"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/ktextaddons/ktextaddons-2.0.1.tar.xz"
)
sha256sums=(
  "b52356be07215f0ace0b8e2a6df8bcd8f3572ef5c0aff89631b043b10adb0c8a"
)

depends=(
  "kf6-karchive"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "kf6-sonnet"
  "kf6-syntax-highlighting"
  "libqt6keychain1"
  "qt6-base"
  "qt6-speech"
)

makedepends=(
  "cmake"
  "doxygen"
  "gettext"
  "graphviz"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kcolorscheme"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kxmlgui"
  "kf6-sonnet"
  "kf6-syntax-highlighting"
  "qt6-base-dev"
  "qt6-multimedia-dev"
  "qt6-speech-dev"
  "qt6-tools-dev"
  "qt6-tools-private-dev"
  "qtkeychain-qt6-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier4"
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
