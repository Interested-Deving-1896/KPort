[update-readmes]   Mode: rewrite — migrating to template structure...
# KPort

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/KPort)

<!-- AI:start:what-it-does -->
KPort provides a Portage-inspired package management system tailored for KDE Neon, integrating Pacstall with support for USE flags and hardware compatibility layers for CPU, GPU, and NPU. It automates the generation of pacscripts from KDE Neon packaging, enabling developers and advanced users to customize and optimize their software installations for specific hardware and use cases.
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
KPort consists of several key components: a hardware compatibility layer for CPU/GPU/NPU detection, a USE flag system for feature toggling, and automated pacscript generation based on KDE Neon packaging. The repository integrates with Pacstall for package management and uses GitHub Actions workflows (`hardware-detect.yml` and `pacscript-ci.yml`) for CI/CD tasks. The directory structure organizes scripts, configuration files, and generated outputs for streamlined development and deployment.

```plaintext
.
├── .devcontainer/       # Development container configuration
├── .github/             # GitHub Actions workflows
├── .gitlab-ci.yml       # GitLab CI configuration
├── bin/                 # Executable scripts
├── config/              # Configuration files for the system
├── db/                  # Database files for package metadata
├── generated/           # Auto-generated pacscripts and related files
├── lib/                 # Shared libraries and utilities
├── overlays/            # Custom package overlays
├── packages/            # Package definitions and metadata
├── scripts/             # Helper scripts for automation
└── README.md            # Project documentation
```
<!-- AI:end:architecture -->

## Install

<!-- Add installation instructions here. This section is yours — the AI will not modify it. -->

```bash
git clone https://github.com/Interested-Deving-1896/KPort.git
cd KPort
```

## Usage

<!-- Add usage examples here. This section is yours — the AI will not modify it. -->

## Configuration

<!-- Document configuration options here. This section is yours — the AI will not modify it. -->

## CI

<!-- AI:start:ci -->
The repository uses GitHub Actions for continuous integration. Workflows are in `.github/workflows/`.

- **pacscript-ci.yml**: Runs on every push or PR touching `packages/`, `config/dep-map.yml`, `lib/`, `bin/kport`, or `scripts/kport/`. Three jobs:
  - *Shell syntax check* — `bash -n` on all 24 scripts under `lib/`, `bin/kport`, and `scripts/kport/`
  - *Lint pacscripts* — validates required fields (`pkgname`, `pkgver`, `sha256sums`, `KSLOT`, `KCATEGORY`), 64-char hex sha256sums, and duplicate `depends`/`makedepends` entries across all pacscripts
  - *Resolver dry-run* — runs `kport_resolve` on five representative leaf packages (kf6-karchive, dolphin, kleopatra, kwin-wayland, qt6-declarative) and fails on missing KPort deps or circular dependency warnings

- **hardware-detect.yml**: Manual workflow (`workflow_dispatch`) that runs the hardware detection scripts and posts CPU/GPU/NPU tier results as a job summary.
<!-- AI:end:ci -->

## Mirror chain

<!-- AI:start:mirror-chain -->
This repo is maintained in [`Interested-Deving-1896/KPort`](https://github.com/Interested-Deving-1896/KPort) and mirrored through:

```
Interested-Deving-1896/KPort  ──►  OpenOS-Project-OSP/KPort  ──►  OpenOS-Project-Ecosystem-OOC/KPort
```

Changes flow downstream automatically via the hourly mirror chain in
[`fork-sync-all`](https://github.com/Interested-Deving-1896/fork-sync-all).
Direct commits to OSP or OOC are detected and opened as PRs back to `Interested-Deving-1896`.
<!-- AI:end:mirror-chain -->

## Contributors

<!-- AI:start:contributors -->
_Contributors pending._
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->
_Original project — no upstream fork._
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
| File | Description |
|---|---|
| [.gitlab/merge_request_templates/Default.md](https://github.com/Interested-Deving-1896/KPort/blob/main/.gitlab/merge_request_templates/Default.md) | GitLab MR template |
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
[MIT](https://github.com/Interested-Deving-1896/KPort/blob/main/LICENSE) © 2026 [Interested-Deving-1896](https://github.com/Interested-Deving-1896)
<!-- AI:end:license -->
