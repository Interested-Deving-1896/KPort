#!/usr/bin/env bash
# KPort pacscript — plasma/plasma-firewall
# Promoted from generated/ — review and test before merging to main
#
# Plasma configuration module for firewalls Plasma Firewall provides a way to

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="plasma-firewall"
pkgver="6.6.5"
pkgdesc="Plasma configuration module for firewalls Plasma"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://invent.kde.org/plasma/plasma-firewall"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/6.6.5/plasma-firewall-6.6.5.tar.xz"
)
sha256sums=(
  "d4acad029c24eaaa98f307e5ff39903aa6a72f373c80f3a3c17ededfa450f8ec"
)

depends=(
  "kf6-kcmutils"
  "kf6-kirigami"
  "kf6-kitemmodels"
  "qml6-module-qtquick-controls"
  "qml6-module-qtquick-layouts"
  "qml6-module-qtquick"
)

makedepends=(
  "cmake"
  "gettext"
  "kf6-extra-cmake-modules"
  "kf6-kauth"
  "kf6-kcmutils"
  "kf6-kcolorscheme"
  "kf6-kconfig"
  "kf6-kconfigwidgets"
  "kf6-kcoreaddons"
  "kf6-kdeclarative"
  "kf6-ki18n"
  "kf6-kservice"
  "kf6-kwidgetsaddons"
  "plasma-libplasma-dev"
  "python3-all-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
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
