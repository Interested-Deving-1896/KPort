#!/usr/bin/env bash
# KPort pacscript — qt6/qt6-grpc
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# translations for Qt 6 Qt is a cross-platform C++ application framework

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="qt6-grpc"
pkgver="6.10.2"
pkgdesc="translations for Qt 6 Qt is a cross-platform C++ application framework"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://www.qt.io/developers/"
license=("GPL-2.0-or-later")

source=(
  "https://download.qt.io/official_releases/qt/6.10/6.10.2/submodules/qtgrpc-everywhere-src-6.10.2.tar.xz"
)
sha256sums=(
  "7386bfc9c10c7920e5ff22dcf067e95f379bb379e4d916269f4465ab295ed136"
)

depends=(
  "protobuf-compiler-grpc"
)

makedepends=(
  "cmake"
  "libgrpc-dev"
  "libgrpc++-dev"
  "libprotobuf-dev"
  "libprotoc-dev"
  "mold"
  "ninja-build"
  "pkg-kde-tools"
  "pkgconf"
  "protobuf-compiler"
  "protobuf-compiler-grpc"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "zlib1g-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
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
