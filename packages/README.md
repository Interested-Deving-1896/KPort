# packages/

Human-reviewed, production-ready pacscripts. Organised by category.

| Category | Contents |
|---|---|
| `frameworks/tier1` | KF6 Tier 1 — no KDE deps (KArchive, KConfig, KCoreAddons, …) |
| `frameworks/tier2` | KF6 Tier 2 — depends only on Tier 1 |
| `frameworks/tier3` | KF6 Tier 3 — depends on Tier 1+2 |
| `frameworks/tier4` | KF6 Tier 4 — depends on Tier 1+2+3 |
| `plasma` | Plasma 6 desktop stack (KWin, Plasma Shell, SDDM, …) |
| `gear` | KDE Gear applications (Dolphin, Konsole, Kdenlive, …) |
| `qt6` | Qt6 base built against KDE Neon's stack |
| `runtime` | Non-KDE runtime dependencies (Mesa, Wayland, PipeWire, …) |
| `tools` | Build tooling (Craft, kde-builder, kdesrc-build, …) |

## Pacscript naming convention

```
packages/<category>/<pkgname>/<pkgname>.pacscript
```

Slotted packages (multiple versions coexisting):

```
packages/<category>/<pkgname>/<pkgname>-<slot>.pacscript
```

Example: `packages/qt6/qt6-base/qt6-base.pacscript`

## Promotion from generated/

Pacscripts start life in `generated/` as auto-generated skeletons.
After human review and testing they are moved here.
A package in `packages/` is considered production-ready.
