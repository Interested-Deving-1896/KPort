#!/usr/bin/env bash
# KPort pacscript — plasma/plasma-nm
# Promoted from generated/ — review and test before merging to main
#
# Plasma 6 networkmanager library

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="plasma-nm"
pkgver="6.6.5"
pkgdesc="Plasma 6 networkmanager library"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://invent.kde.org/plasma/plasma-nm.git"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/plasma-nm-6.6.5.tar.xz"
)
sha256sums=(
  "c92d09d2978dbbe6b5c897beac822cd053c17473f1d61506e152bfcb46b70b9b"
)

depends=(
  "kf6-kcmutils"
  "kf6-kcoreaddons"
  "kf6-kdeclarative"
  "kf6-kirigami"
  "kf6-kquickcharts"
  "kf6-ksvg"
  "kf6-prison"
  "libplasma6"
  "mobile-broadband-provider-info"
  "network-manager"
  "qt6-declarative-dev"
)

makedepends=(
  "cmake"
  "gettext"
  "kf6-extra-cmake-modules"
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kcompletion"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-kdeclarative"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kirigami"
  "kf6-kirigami-addons-dev"
  "kf6-kitemmodels"
  "kf6-kitemviews"
  "kf6-knotifications"
  "kf6-kquickcharts-dev"
  "kf6-kservice"
  "kf6-ksvg"
  "kf6-kwallet"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "kf6-modemmanager-qt-dev"
  "kf6-networkmanager-qt-dev"
  "kf6-prison"
  "kf6-solid"
  "libcups2-dev"
  "libnm-dev"
  "libopenconnect-dev"
  "plasma-libplasma-dev"
  "libqca-qt6-dev"
  "mobile-broadband-provider-info"
  "modemmanager-dev"
  "pkgconf"
  "qcoro-qt6-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-tools-dev"
  "qt6-webengine-dev"
  "qtkeychain-qt6-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl4"

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
