# KPort

Portage-inspired KDE Neon package repository using Pacstall.

KPort brings the Portage philosophy — USE flags, slots, dependency graphs,
overlays, and hardware-aware builds — to the KDE Neon / Ubuntu LTS ecosystem.
Packages are auto-generated from KDE Neon's Debian packaging metadata and
refined by hand before promotion to production.

## Architecture

```
invent.kde.org/neon/{kde,kf6,qt6,neon-packaging}
        ↓  generate-pacscripts.sh (reads debian/control)
generated/<category>/          ← auto-generated skeletons
        ↓  human review + test
packages/<category>/           ← production-ready pacscripts
        ↓  kport install
~/.local/share/kport/db/       ← installed package database
```

## Package categories

| Category | Contents |
|---|---|
| `frameworks/tier1–4` | KDE Frameworks 6, ordered by dependency tier |
| `plasma` | Plasma 6 desktop stack (KWin, Plasma Shell, SDDM, …) |
| `gear` | KDE Gear applications (Dolphin, Konsole, Kdenlive, …) |
| `qt6` | Qt6 base built against KDE Neon's stack |
| `runtime` | Non-KDE runtime dependencies (Mesa, Wayland, PipeWire, …) |
| `tools` | Build tooling (Craft, kde-builder, kdesrc-build, …) |

## Hardware compatibility

KPort detects your hardware at install time and automatically sets
appropriate USE flags. Three detection tiers:

### CPU tiers (via [x86-64-level](https://github.com/HenrikBengtsson/x86-64-level) + [cpuinfo](https://github.com/pytorch/cpuinfo))

| Tier | Requirements |
|---|---|
| `x86-64-v1` | Baseline SSE/SSE2 |
| `x86-64-v2` | + SSE3, SSSE3, SSE4.1/4.2, POPCNT |
| `x86-64-v3` | + AVX, AVX2, BMI1/2, FMA |
| `x86-64-v4` | + AVX-512 |
| `aarch64` | 64-bit ARM baseline |
| `aarch64-v8.2` | + SVE, dotprod, fp16 |

### GPU tiers

| Tier | Requirements | Auto-enables |
|---|---|---|
| `gpu-sw` | Software rendering | — |
| `gpu-gl2` | OpenGL 2.x | — |
| `gpu-gl4` | OpenGL 4.x + Vulkan 1.0 | `opengl` |
| `gpu-vk12` | Vulkan 1.2 + compute | `opengl vulkan` |
| `gpu-vk13` | Vulkan 1.3 + mesh shaders | `opengl vulkan` |

Vendor flags: `gpu-intel` `gpu-amd` `gpu-nvidia` `gpu-nvidia-proprietary`
Auto-enables: `vaapi` (Intel/AMD), `vdpau` (NVIDIA legacy), `cuda` (NVIDIA proprietary), `rocm` (AMD)

### NPU / AI accelerator tiers

| Tier | Requirements | Auto-enables |
|---|---|---|
| `npu-none` | No NPU | — |
| `npu-igpu` | iGPU OpenCL compute | `opencl` |
| `npu-dedicated` | Dedicated NPU (<10 TOPS) | `opencl npu` |
| `npu-ai` | Full AI accelerator (≥10 TOPS) | `opencl npu llm-local` |
| `npu-datacenter` | Datacenter-class | `opencl npu llm-local` |

Supported hardware: Intel NPU (Meteor/Lunar/Arrow Lake), AMD XDNA (Ryzen AI),
NVIDIA Tensor Cores, Qualcomm HTP, Arm Ethos-N.

### Running detection

```bash
kport detect              # detect and write ~/.config/kport/hardware.conf
kport detect --dry-run    # show what would be written
kport detect --show-flags # show derived USE flags
kport detect --json       # JSON output
kport detect --update     # re-detect and overwrite existing conf
```

## USE flags

USE flags control compile-time features. Defaults are set automatically
from hardware detection. Override in `~/.config/kport/use.conf`:

```bash
# ~/.config/kport/use.conf
wayland=true
x11=true
vulkan=true      # auto-set from GPU tier
vaapi=true       # auto-set from GPU vendor
pipewire=true
bluetooth=true
debug=false
docs=false
test=false
```

Per-package overrides in `~/.config/kport/package.use`:

```bash
# format: category/pkgname flag=value
plasma/kwin vulkan=true x11=false
frameworks/tier1/karchive docs=true
```

## Slots

Multiple versions of the same package can coexist using slots.
KPort uses slots for Qt5/Qt6 and KF5/KF6 coexistence:

```bash
kport install qt6-base:6      # install Qt6 slot
kport install qt6-base:5      # install Qt5 slot alongside
```

## Overlays

Third-party package trees layered on top of KPort. Register in
`config/repositories.yml` or add to `overlays/` locally.

## Neon channels (stability)

| Channel | KPort keyword | Description |
|---|---|---|
| Neon User | `stable` | Tested, recommended |
| Neon Testing | `testing` | RC-quality, mostly stable |
| Neon Unstable | `unstable` | Git builds, may break |

Default: `stable` + `testing`. Accept unstable per-package in
`~/.config/kport/package.accept_keywords`.

## Package sets

Install a full stack in one command:

```bash
kport install @kde-frameworks   # all KF6 tiers
kport install @kde-plasma       # Plasma 6 desktop
kport install @kde-gear         # KDE Gear apps
kport install @kde-full         # everything
```

## CI / GitHub Actions

| Workflow | Purpose |
|---|---|
| `hardware-detect.yml` | Validate detection scripts on GitHub runners |
| `generate-pacscripts.yml` | Auto-generate pacscript skeletons from Neon packaging |
| `validate-pacscripts.yml` | Lint and format-check all pacscripts |
| `test-build.yml` | Test-build promoted packages in a clean Neon container |

## Contributing

1. Check `generated/<category>/` for auto-generated skeletons needing review
2. Test: `pacstall -Il generated/<category>/<pkg>/<pkg>.pacscript`
3. Fix any issues, move to `packages/<category>/<pkg>/`
4. Open a PR — CI validates format and runs a test build

See `packages/PACSCRIPT_FORMAT.md` for the full pacscript spec including
KPort extensions (`KSLOT`, `KCATEGORY`, `KUSE`, `KCPU_MIN`, `KGPU_MIN`, `KNPU_MIN`).

## Related projects

- [KDE Neon](https://neon.kde.org/) — upstream packaging source
- [Pacstall](https://github.com/pacstall/pacstall) — package manager
- [KDE Craft](https://github.com/KDE/craft) — KDE build system
- [kde-builder](https://github.com/KDE/kde-builder) — KDE source builder
- [x86-64-level](https://github.com/HenrikBengtsson/x86-64-level) — CPU tier detection
- [cpuinfo](https://github.com/pytorch/cpuinfo) — CPU feature detection
