#!/usr/bin/env bash
# KPort pacscript — plasma/kf6-plasma-framework
# Promoted from generated/ — review and test before merging to main
#
# Plugin based UI runtime used to write primary user interfaces

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-plasma-framework"
pkgver="6.6.5"
pkgdesc="Plugin based UI runtime used to write primary user interfaces"
url="https://invent.kde.org/frameworks/plasma-framework"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/libplasma-6.6.5.tar.xz"
)
sha256sums=(
  "82e02b2098f4bac90f28cdd4f9d3a4da4557440ec8347220d8fee293c1f98d8b"
)

depends=(
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kglobalaccel"
  "kf6-ki18n"
  "kf6-kiconthemes"
  "kf6-kio"
  "kf6-kirigami"
  "kf6-knotifications"
  "kf6-kpackage"
  "kf6-ksvg"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "libegl1"
  "libglx0"
  "libopengl0"
  "libwayland-client0"
  "libx11-6"
  "libxcb-composite0"
  "libxcb-damage0"
  "libxcb-render0"
  "libxcb1"
  "plasma-activities"
  "qml6-module-org-kde-kconfig"
  "qml6-module-org-kde-kirigami2"
  "qml6-module-org-kde-kquickcontrols"
  "qml6-module-org-kde-kquickcontrolsaddons"
  "qml6-module-qtqml-models"
  "qml6-module-qtquick"
  "qml6-module-qtquick-controls"
  "qml6-module-qtquick-templates"
  "qt6-base"
  "qt6-declarative"
  "qt6-wayland"
)

makedepends=(
  "cmake"
  "doxygen"
  "gettext"
  "graphviz"
  "kf6-kactivities"
  "kf6-extra-cmake-modules"
  "kf6-karchive"
  "kf6-kcmutils"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kdbusaddons"
  "kf6-kdeclarative"
  "kf6-kdoctools"
  "kf6-kglobalaccel"
  "kf6-kguiaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kirigami"
  "kf6-knotifications"
  "kf6-kpackage"
  "kf6-kparts"
  "kf6-ksvg"
  "kf6-kwidgetsaddons"
  "kf6-kwindowsystem"
  "kf6-kxmlgui"
  "libegl1-mesa-dev"
  "libsm-dev"
  "libx11-xcb-dev"
  "libxcb-composite0-dev"
  "libxcb-damage0-dev"
  "libxcb-shape0-dev"
  "libwayland-dev"
  "pkg-config"
  "plasma-wayland-protocols"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-svg-dev"
  "qt6-tools-dev"
  "qt6-wayland-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="unstable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl2"

KUSE=(
  "+wayland"
  "+x11"
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
