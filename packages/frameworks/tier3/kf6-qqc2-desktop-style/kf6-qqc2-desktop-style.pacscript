#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-qqc2-desktop-style
# Promoted from generated/ — review and test before merging to main
#
# Qt Quick Controls 2: Desktop Style Small style written in QML for

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-qqc2-desktop-style"
pkgver="6.26.0"
pkgdesc="Qt Quick Controls 2: Desktop Style Small style written in QML for"
url="https://cgit.kde.org/qqc2-desktop-style.git/"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/qqc2-desktop-style-6.26.0.tar.xz"
)
sha256sums=(
  "1805fa31355ff86c02158fd2b8d396fd88835d01db97d8700314c48ee3360986"
)

depends=(
  "kf6-sonnet"
)

makedepends=(
  "cmake"
  "dbus-x11"
  "kf6-extra-cmake-modules"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kiconthemes"
  "kf6-kirigami"
  "kf6-sonnet"
  "pkgconf"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
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
