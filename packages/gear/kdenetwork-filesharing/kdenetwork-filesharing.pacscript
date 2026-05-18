#!/usr/bin/env bash
# KPort pacscript — gear/kdenetwork-filesharing
# Promoted from generated/ — review and test before merging to main
#
# network filesharing configuration module This package provides a way to

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kdenetwork-filesharing"
pkgver="26.04.1"
pkgdesc="network filesharing configuration module"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.kde.org/"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/release-service/26.04.1/src/kdenetwork-filesharing-26.04.1.tar.xz"
)
sha256sums=(
  "76665219c66ba71137f00634036427028903cc146226d3d2c933aac3d232e757"
)

depends=(
  "kf6-kauth"
  "kf6-kcoreaddons"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "~apt:libpackagekitqt6"
  "~apt:libqcoro6dbus0t64"
  "qt6-base"
  "qt6-declarative"
)

makedepends=(
  "cmake"
  "kf6-extra-cmake-modules"
  "kf6-kcoreaddons"
  "kf6-kdeclarative"
  "kf6-kdoctools"
  "kf6-ki18n"
  "kf6-kio"
  "kf6-kwidgetsaddons"
  "libpackagekitqt6-dev"
  "qcoro-qt6-dev"
  "qt6-base-dev"
  "qt6-declarative-dev"
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
