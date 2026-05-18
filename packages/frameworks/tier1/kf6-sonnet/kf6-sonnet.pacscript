#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/kf6-sonnet
# Promoted from generated/ — review and test before merging to main
#
# Support for spellchecking

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-sonnet"
pkgver="6.26.0"
pkgdesc="Support for spellchecking"
url="http://projects.kde.org/sonnet"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/sonnet-6.26.0.tar.xz"
)
sha256sums=(
  "3ac4e165c0b3c79eda416b754bb837292f354188a1220f2065f57f686489af25"
)

depends=(
  "hspell"
)

makedepends=(
  "aspell"
  "cmake"
  "doxygen"
  "graphviz"
  "hspell"
  "kf6-extra-cmake-modules"
  "libaspell-dev"
  "libhunspell-dev"
  "libvoikko-dev"
  "pkgconf"
  "qt6-5compat-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
  "xauth"
  "xvfb"
  "zlib1g-dev"
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
