# db/

Local package database — tracks installed packages, their versions, USE flags
used at build time, and file manifests.

This directory is **not committed to git**. It is created and managed by
`kport` at runtime in `~/.local/share/kport/db/` (or `KPORT_DB_DIR` if set).

## Structure (runtime, not in repo)

```
db/
  world                        # explicitly installed packages (one per line)
  installed/
    <pkgname>/
      version                  # installed version string
      slot                     # KSLOT value
      use_flags                # USE flags active at build time
      hardware_conf            # hardware.conf snapshot at build time
      files                    # newline-separated list of installed files
      build_log                # last build log (last 500 lines)
```

## world file

Lists packages explicitly requested by the user (not pulled in as deps).
Used by `kport upgrade` to determine what to keep vs what can be auto-removed.

Format: one `category/pkgname` per line, e.g.:
```
plasma/plasma-desktop
gear/dolphin
frameworks/tier1/karchive
```
