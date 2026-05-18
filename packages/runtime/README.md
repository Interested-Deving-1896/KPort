# packages/runtime/

Non-KDE runtime dependencies built from source against KDE Neon's stack.

Candidates: Mesa, Wayland, PipeWire, libinput, xkbcommon, fontconfig, …

All current runtime deps (Mesa, Wayland, GStreamer, etc.) are satisfied by
KDE Neon's apt packages and mapped via `config/dep-map.yml` with `~apt:`
prefixes. Source-built packages will be added here as needed.
