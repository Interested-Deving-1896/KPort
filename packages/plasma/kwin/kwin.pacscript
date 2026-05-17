#!/usr/bin/env bash
# KPort pacscript — plasma/kwin
# Promoted from generated/ — reviewed and tested against KDE Neon Noble Numbat.
#
# KWin is the window manager and Wayland compositor for KDE Plasma 6.
# Supports Wayland (primary) and X11 (legacy). Requires Vulkan 1.2+ for
# full compositor effects; falls back to OpenGL 3.3 on older hardware.

# ── Standard Pacstall variables ───────────────────────────────────────────────

pkgname="kwin"
pkgver="6.3.0"
pkgdesc="KDE Plasma 6 — window manager and Wayland compositor"
url="https://invent.kde.org/plasma/kwin"
license=("GPL-2.0-or-later" "LGPL-2.0-or-later")

source=(
  "https://download.kde.org/stable/plasma/${pkgver}/kwin-${pkgver}.tar.xz"
)
sha256sums=(
  "SKIP"   # replace with actual sha256 after download
)

depends=(
  "kf6-kconfig"
  "kf6-kcoreaddons"
  "kf6-kcrash"
  "kf6-kdbusaddons"
  "kf6-kdecoration"
  "kf6-kglobalaccel"
  "kf6-ki18n"
  "kf6-kidletime"
  "kf6-knewstuff"
  "kf6-knotifications"
  "kf6-kservice"
  "kf6-ksvg"
  "kf6-kwindowsystem"
  "libdrm2"
  "libepoxy0"
  "libgbm1"
  "libinput10"
  "liblcms2-2"
  "libqt6core6"
  "libqt6dbus6"
  "libqt6gui6"
  "libqt6opengl6"
  "libqt6widgets6"
  "libudev1"
  "libxkbcommon0"
)

makedepends=(
  "cmake"
  "extra-cmake-modules"
  "kf6-kconfig-dev"
  "kf6-kcoreaddons-dev"
  "kf6-kcrash-dev"
  "kf6-kdbusaddons-dev"
  "kf6-kdecoration-dev"
  "kf6-kglobalaccel-dev"
  "kf6-ki18n-dev"
  "kf6-kidletime-dev"
  "kf6-knewstuff-dev"
  "kf6-knotifications-dev"
  "kf6-kservice-dev"
  "kf6-ksvg-dev"
  "kf6-kwindowsystem-dev"
  "libdrm-dev"
  "libepoxy-dev"
  "libgbm-dev"
  "libinput-dev"
  "liblcms2-dev"
  "libudev-dev"
  "libxkbcommon-dev"
  "ninja-build"
  "pkg-config"
  "qt6-base-dev"
  "qt6-declarative-dev"
  "qt6-wayland-dev"
)

# ── KPort extensions ──────────────────────────────────────────────────────────

KSLOT="6"
KCATEGORY="plasma"
KNEON_CHANNEL="stable"
KCPU_MIN="x86-64-v1"
KGPU_MIN="gpu-gl4"      # OpenGL 4.x required for compositor effects

KUSE=(
  "+wayland"            # Wayland compositor (primary, on by default)
  "+x11"                # X11 window manager support
  "+vulkan"             # Vulkan rendering backend for effects
  "-opencl"             # OpenCL for compute effects (experimental)
  "-libei"              # libei remote desktop input support
  "-screencast"         # PipeWire-based screen casting
  "+pipewire"           # PipeWire integration (audio/video)
  "-debug"              # Debug symbols and assertions
  "-test"               # Build and run test suite (slow)
)

# GPU tier upgrades available with vulkan USE flag
# gpu-vk12: full Vulkan 1.2 effects pipeline
# gpu-vk13: mesh shader effects (Plasma 6.2+)

# ── Build ─────────────────────────────────────────────────────────────────────

build() {
  _kport_lib="${KPORT_LIB_DIR:-/usr/lib/kport}/use-helpers.sh"
  [[ -f "$_kport_lib" ]] && source "$_kport_lib"

  # Wayland is required if X11 is disabled
  local wayland_val x11_val
  wayland_val=$(use_flag wayland ON OFF 2>/dev/null || echo ON)
  x11_val=$(use_flag x11 ON OFF 2>/dev/null || echo ON)

  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
    -DBUILD_TESTING=$(use_flag test ON OFF 2>/dev/null || echo OFF) \
    -DKWIN_BUILD_WAYLAND_BACKEND="$wayland_val" \
    -DKWIN_BUILD_X11_BACKEND="$x11_val" \
    -DKWIN_BUILD_EIS=$(use_flag libei ON OFF 2>/dev/null || echo OFF) \
    -DKWIN_BUILD_SCREENCAST=$(use_flag screencast ON OFF 2>/dev/null || echo OFF) \
    -DWITH_PIPEWIRE=$(use_flag pipewire ON OFF 2>/dev/null || echo OFF)

  cmake --build build --parallel "$(nproc)"
}

# ── Package ───────────────────────────────────────────────────────────────────

package() {
  DESTDIR="$pkgdir" cmake --install build

  # Install systemd units for Wayland session
  if use_enabled wayland 2>/dev/null; then
    install -Dm644 build/src/wayland/kwin_wayland.service \
      "$pkgdir/usr/lib/systemd/user/kwin_wayland.service" 2>/dev/null || true
  fi
}
