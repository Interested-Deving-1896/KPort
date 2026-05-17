#!/usr/bin/env bash
# KPort pacscript — frameworks/tier1/karchive
# Promoted from generated/ — reviewed and tested against KDE Neon Noble Numbat.
#
# KArchive provides classes for easy reading, creation and manipulation of
# "archive" formats like ZIP and TAR. Part of KDE Frameworks 6 Tier 1.

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kf6-karchive"
pkgver="6.3.0"
pkgdesc="KDE Frameworks 6 — file archiving and compression library"
url="https://invent.kde.org/frameworks/karchive"
license=("LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/frameworks/${pkgver%.*}/karchive-${pkgver}.tar.xz"
)
sha256sums=(
  "SKIP"   # replace with actual sha256 after download
)

depends=(
  "libbz2-1.0"
  "liblzma5"
  "zlib1g"
  "libzstd1"
  "qt6-base"
)

makedepends=(
  "cmake"
  "extra-cmake-modules"
  "qt6-base-dev"
  "libbz2-dev"
  "liblzma-dev"
  "zlib1g-dev"
  "libzstd-dev"
  "pkg-config"
  "ninja-build"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="frameworks/tier1"
KNEON_CHANNEL="stable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-sw"

KUSE=(
  "-docs"    # API documentation via QDoc
  "-test"    # Build and run test suite
)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  # Source KPort USE flag helpers
  # shellcheck source=/usr/lib/kport/use-helpers.sh
  [[ -f /usr/lib/kport/use-helpers.sh ]] && source /usr/lib/kport/use-helpers.sh

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
