#!/usr/bin/env bash
# KPort pacscript — community-32bit/lxqt/lxqt-themes
#
# LXQt QSS stylesheets, wallpapers, and theme assets.
# Pure data — no compiled output, installs on any arch.

pkgname="lxqt-themes"
pkgver="1.3.0"
pkgdesc="LXQt themes, stylesheets, and wallpapers"
url="https://github.com/lxqt/lxqt-themes"
license=("LGPL-2.1-or-later")

# lxqt-themes has no 1.4.0 release — it went from 1.3.0 directly to 2.0.0.
# 1.3.0 is the correct version for the LXQt 1.4.0 desktop era.
source=(
  "https://github.com/lxqt/lxqt-themes/releases/download/${pkgver}/lxqt-themes-${pkgver}.tar.xz"
)
sha256sums=(
  "217fec5bb2c1d5b92c9b07d470a960d1fbfeeac927c12f54a85c5e9c25c67504"
)

makedepends=(
  "cmake"
  "ninja-build"
  "lxqt-build-tools"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="lxqt"
KNEON_CHANNEL="stable"
# Pure data — no KCPU_MIN
KGPU_MIN="gpu-sw"

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build
}
