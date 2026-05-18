#!/usr/bin/env bash
# KPort pacscript — community-32bit/utils/terminal/xterm
#
# xterm is a minimal X11 terminal emulator with no Qt or GTK dependency.
# It builds cleanly on i686 and serves as the reference example for
# community-32bit overlay pacscripts.

pkgname="xterm"
pkgver="394"
pkgdesc="X11 terminal emulator"
url="https://invisible-island.net/xterm/"
license=("MIT")

source=(
  "https://invisible-mirror.net/archives/xterm/xterm-394.tgz"
)
sha256sums=(
  "a2a0cb206eb0423dedc34794f5c2d38c83390d2dd1106b66aba0960c3a976c7a"
)

depends=(
  "libx11-6"
  "libxft2"
  "libxaw7"
  "libxmu6"
  "libxt6"
  "libncurses6"
  "libutempter0"
)

makedepends=(
  "libx11-dev"
  "libxft-dev"
  "libxaw7-dev"
  "libxmu-dev"
  "libxt-dev"
  "libncurses-dev"
  "libutempter-dev"
  "xbitmaps"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="0"
KCATEGORY="utils/terminal"
KNEON_CHANNEL="stable"

# i686-baseline: SSE2 only — xterm has no SIMD requirements.
# Remove KCPU_MIN entirely if the package runs on any arch (including aarch64).
KCPU_MIN="i686-baseline"

# xterm renders via X11 software paths; no GPU acceleration needed.
KGPU_MIN="gpu-sw"

KUSE=(
  "+xft"     # FreeType font rendering via Xft (recommended)
  "-luit"    # Unicode locale input translator (rarely needed)
  "-toolbar" # Toolbar widget (adds libXaw dependency weight)
)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  _kport_lib="${KPORT_LIB_DIR:-/usr/lib/kport}/use-helpers.sh"
  [[ -f "$_kport_lib" ]] && source "$_kport_lib"

  local configure_args=(
    --prefix=/usr
    --sysconfdir=/etc
    --enable-256-color
    --enable-wide-chars
    --enable-luit=$(use_flag luit yes no 2>/dev/null || echo no)
    --with-xft=$(use_flag xft yes no 2>/dev/null || echo yes)
  )

  ./configure "${configure_args[@]}"
  make -j"$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  make DESTDIR="$pkgdir" install

  # Desktop entry
  install -Dm644 xterm.desktop \
    "$pkgdir/usr/share/applications/xterm.desktop"
}
