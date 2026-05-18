#!/usr/bin/env bash
# KPort pacscript — qt6/libqca-qt6-2
# Promoted from generated/ — reviewed against KDE Neon Qt6 packaging.
#
# libraries for the Qt Cryptographic Architecture The Qt Cryptographic

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="libqca-qt6-2"
pkgver="2.3.9"
pkgdesc="libraries for the Qt Cryptographic Architecture The Qt Cryptographic"
# Fall back to invent.kde.org canonical URL when no homepage is set
url="https://userbase.kde.org/QCA"
license=("GPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/qca/2.3.9/qca-2.3.9.tar.xz"
)
sha256sums=(
  "c555d5298cdd7b6bafe2b1f96106f30cfa543a23d459d50c8a91eac33c476e4e"
)

depends=(
  # No named runtime deps found in debian/control (only ${shlibs:Depends}).
  # Populate after a test build by inspecting ldd output or dpkg -I.
)

makedepends=(
  "ca-certificates"
  "cmake"
  "doxygen"
  "gnupg"
  "graphviz"
  "libsasl2-dev"
  "libssl-dev"
  "pkg-config"
  "qt6-5compat-dev"
  "qt6-base-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="qt6"
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
