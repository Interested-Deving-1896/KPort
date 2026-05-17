# overlays/

Third-party package trees layered on top of the main KPort tree.
Analogous to Portage overlays / Gentoo repositories.

Each overlay is a directory with the same structure as the root `packages/` tree.
KPort resolves packages by searching overlays in priority order before falling
back to the main tree.

## Adding an overlay

1. Create a directory under `overlays/<name>/`
2. Add a `metadata.yml` describing the overlay
3. Register it in `config/repositories.yml`

## Example overlay layout

```
overlays/
  my-overlay/
    metadata.yml
    packages/
      plasma/
        my-custom-plasmoid/
          my-custom-plasmoid.pacscript
```

## `metadata.yml` format

```yaml
name: my-overlay
description: Custom Plasma plasmoids
maintainer: your-github-handle
url: https://github.com/you/my-kport-overlay
priority: 50        # higher = checked first (main tree = 0)
```
