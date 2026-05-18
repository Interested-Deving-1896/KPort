#!/usr/bin/env bash
# KPort pacscript — frameworks/tier3/kf6-purpose
# Promoted from generated/ — review and test before merging to main
#
# abstraction to provide and leverage actions of a specific kind, runtime Purpose

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-purpose"
pkgver="6.26.0"
pkgdesc="abstraction to provide and leverage actions of a specific kind, runtime Purpose"
url="https://cgit.kde.org/purpose.git/"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/6.26/purpose-6.26.0.tar.xz"
)
sha256sums=(
  "cc7b7599d1ac7ce7ed07351a35d742fac1b7e554b208a7b1c92e859b3b4add30"
)

depends=(
  "kf6-bluez-qt"
  "kf6-kcmutils"
  "kf6-kirigami"
  "kf6-prison"
  "qml6-module-sso-onlineaccounts"
  "qt6-5compat"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "intltool"
  "kaccounts-integration-dev"
  "kf6-extra-cmake-modules"
  "kf6-kcmutils-dev"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kdeclarative-dev"
  "kf6-ki18n-dev"
  "kf6-kio-dev"
  "kf6-kirigami-dev"
  "kf6-knotifications-dev"
  "kf6-kwallet-dev"
  "kf6-prison-dev"
  "libaccounts-glib-dev"
  "pkgconf"
  "qml6-module-sso-onlineaccounts"
  "qt6-5compat-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier3"
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
