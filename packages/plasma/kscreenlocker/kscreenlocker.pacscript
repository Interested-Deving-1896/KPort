#!/usr/bin/env bash
# KPort pacscript — plasma/kscreenlocker
# Promoted from generated/ — review and test before merging to main
#
# Library and runtime files for kscreenlocker Library and components for secure

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kscreenlocker"
pkgver="6.6.5"
pkgdesc="Library and runtime files for kscreenlocker Library and components for secure"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://projects.kde.org/kscreenlocker"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/kscreenlocker-6.6.5.tar.xz"
)
sha256sums=(
  "9ba0aee32364051eeb213d48dd3c208ae0ce7062190a30f855735ba4efe389cc"
)

depends=(
  "kf6-kcmutils"
  "kf6-kdeclarative"
  "kf6-kirigami"
  "psmisc"
  "qml6-module-qtquick"
  "qml6-module-qtquick-controls"
  "qml6-module-qtquick-layouts"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kcrash"
  "kf6-kdeclarative"
  "kf6-kglobalaccel"
  "kf6-ki18n"
  "kf6-kidletime"
  "kf6-kio"
  "kf6-knotifications"
  "kf6-ksvg"
  "kf6-ktextwidgets"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-solid"
  "kwayland-dev"
  "libkf6screen-dev"
  "liblayershellqtinterface-dev"
  "libpam0g-dev"
  "plasma-libplasma-dev"
  "libseccomp-dev"
  "libwayland-dev"
  "libx11-dev"
  "libxcb-keysyms1-dev"
  "libxcb-xtest0-dev"
  "libxcb1-dev"
  "libxcursor-dev"
  "libxi-dev"
  "pkgconf"
  "qt6-base-dev"
  "qt6-declarative-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "+wayland"
  "+x11"
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
