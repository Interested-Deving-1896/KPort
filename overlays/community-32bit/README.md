# community-32bit overlay

Lightweight packages for i686 (32-bit x86) systems.

Qt 6 and KDE Frameworks 6 require a 64-bit target and cannot be built for
i686. This overlay provides packages that still build and run on 32-bit:
terminal emulators, file managers, media players, and utilities that use
GTK3/GTK4, SDL2, or have no GUI toolkit dependency.

## Scope

**Included:**
- Terminal emulators (xterm, rxvt-unicode, st)
- Lightweight file managers (Thunar, PCManFM, Midnight Commander)
- Media players (mpv, VLC, mplayer)
- Text editors (geany, mousepad, leafpad)
- System utilities with no Qt6 dependency

**Excluded:**
- Anything that depends on Qt 6 or KDE Frameworks 6
- Packages requiring a 64-bit address space (Chromium, Electron, etc.)
- KDE Plasma desktop components

## Package format

Pacscripts here follow the standard KPort format with two i686-specific
conventions:

1. Set `KCPU_MIN` to `i686-baseline` or `i686-sse3` (not `x86-64-*`).
2. Set `KGPU_MIN` to `gpu-sw`, `gpu-gl2`, or `gpu-gl4` — never `gpu-vk*`.

See `utils/terminal/xterm/xterm.pacscript` for a minimal working example.

## Enabling this overlay

Add the following to `config/repositories.yml`:

```yaml
- name: community-32bit
  description: "Lightweight i686 packages"
  url: https://github.com/your-org/kport-community-32bit
  priority: 15
  enabled: true
  auto_sync: true
```

Or for local development, copy this directory into your KPort installation's
`overlays/` tree and set `enabled: true` in `metadata.yml`.
