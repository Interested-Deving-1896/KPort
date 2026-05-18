# KPort Pacscript Format

KPort pacscripts are standard Pacstall pacscripts extended with KPort-specific
variables. All standard Pacstall variables work as documented in
https://github.com/pacstall/pacstall/wiki/Pacscript-101

## Standard variables (required)

```bash
pkgname=""        # package name (lowercase, hyphens, no underscores)
pkgver=""         # upstream version (e.g. "6.3.0")
pkgdesc=""        # one-line description
url=""            # upstream homepage
license=()        # SPDX license identifiers
source=()         # source URLs (supports $pkgver substitution)
sha256sums=()     # checksums matching source array
depends=()        # runtime dependencies
makedepends=()    # build-time dependencies
```

## Standard variables (optional)

```bash
provides=()       # virtual packages this satisfies (e.g. "virtual/qt6")
conflicts=()      # packages that cannot coexist
replaces=()       # packages this supersedes
backup=()         # config files to protect on upgrade
gives=""          # binary/command this package provides
```

## KPort extensions

### KSLOT — parallel installation slot

```bash
KSLOT="6"         # install slot (default: "0" = unslotted)
                  # slotted packages install to /usr/lib/<pkg>-<slot>/
                  # and can coexist with other slots
```

### KCATEGORY — package category

```bash
KCATEGORY="frameworks/tier1"   # must match directory under packages/
```

### KNEON_CHANNEL — minimum Neon channel

```bash
KNEON_CHANNEL="stable"   # stable | testing | unstable
                         # packages marked unstable are masked by default
```

### KUSE — USE flag declarations

Declares which USE flags this package supports and their default state.
Format: flag name, +/- prefix for default on/off, description after #.

```bash
KUSE=(
  "+wayland"      # Wayland compositor support (on by default)
  "-x11"          # X11 fallback support (off by default)
  "+vulkan"       # Vulkan rendering backend
  "-opencl"       # OpenCL compute support
  "-debug"        # Debug symbols and assertions
  "-docs"         # API documentation
  "-test"         # Build and run test suite
)
```

### KCPU_MIN — minimum CPU tier

```bash
KCPU_MIN="x86-64-v1"   # i686-baseline | i686-sse3
                        # x86-64-v1 | x86-64-v2 | x86-64-v3 | x86-64-v4
                        # aarch64-v8 | aarch64-v8.2 | aarch64-v9 | aarch64-v9.2
                        # riscv64-rv64gc | riscv64-rv64gcv
```

Omit `KCPU_MIN` entirely for packages that produce no compiled, arch-specific
output (pure data, icons, translations, themes). Setting `KCPU_MIN="x86-64-v1"`
on such packages incorrectly blocks installation on aarch64 and riscv64.

### KGPU_MIN — minimum GPU tier

```bash
KGPU_MIN="gpu-sw"      # gpu-sw | gpu-gl2 | gpu-gl4 | gpu-vk12 | gpu-vk13
                        # gpu-mali-g52 | gpu-mali-g610 | gpu-immortalis-g715
                        # gpu-adreno-6xx | gpu-adreno-7xx
                        # gpu-img-bxm
```

On i686, the maximum available tier is `gpu-gl4`. Do not set `KGPU_MIN` to
`gpu-vk12` or `gpu-vk13` for packages targeting 32-bit — no Vulkan ICD ships
a 32-bit userspace library.

## 32-bit (i686) support

The main `packages/` tree targets 64-bit platforms only. Qt 6 and KDE
Frameworks 6 require a 64-bit target; there is no supported path to build them
for i686.

32-bit packages live in the `community-32bit` overlay
(`overlays/community-32bit/`). Packages there must:

- Use a toolkit that still supports i686: GTK3, GTK4, SDL2, ncurses, or none.
- Set `KCPU_MIN` to `i686-baseline` or `i686-sse3` (not `x86-64-*`).
- Set `KGPU_MIN` to `gpu-sw`, `gpu-gl2`, or `gpu-gl4`.
- Not depend on any package from the main KPort tree that carries
  `KCPU_MIN="x86-64-*"`.

### KNPU_MIN — minimum NPU tier (optional, for AI-accelerated packages)

```bash
KNPU_MIN="npu-none"    # npu-none | npu-igpu | npu-dedicated | npu-ai | npu-datacenter
```

## USE flag conditionals in build()

The KPort runtime sources `use-helpers.sh` before calling `build()`.
This provides `use_enabled`, `use_disabled`, and `use_flag` helpers.

The helpers are installed to `/usr/lib/kport/` by default (`sudo scripts/kport/setup-runtime.sh`).
For user installs, set `KPORT_LIB_DIR=~/.local/lib/kport` in your environment.

```bash
build() {
  cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_TESTING=$(use_flag test ON OFF)
    -DWITH_WAYLAND=$(use_flag wayland ON OFF)
    -DWITH_X11=$(use_flag x11 ON OFF)
    -DWITH_VULKAN=$(use_flag vulkan ON OFF)
  )

  cmake -B build "${cmake_args[@]}"
  cmake --build build --parallel "$(nproc)"
}
```

## package() function

```bash
package() {
  DESTDIR="$pkgdir" cmake --install build

  # USE flag conditional file installation
  if use_enabled docs; then
    install -Dm644 build/docs/html/* "$pkgdir/usr/share/doc/$pkgname/"
  fi
}
```

## Full example

See `packages/frameworks/tier1/karchive/karchive.pacscript` for a minimal
real-world example, and `packages/plasma/kwin/kwin.pacscript` for a complex
example with USE flags, slots, and hardware tier requirements.
