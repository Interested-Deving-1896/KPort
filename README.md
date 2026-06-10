[update-readmes]   Mode: rewrite — migrating to template structure...
# KPort

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/KPort)

<!-- AI:start:what-it-does -->
This project provides a Portage-inspired package repository for KDE Neon, integrating Pacstall, USE flags, and hardware compatibility layers for CPU, GPU, and NPU configurations. It automates the generation of pacscripts from KDE Neon packaging and supports streamlined package management tailored to specific hardware setups. It is used by developers and system maintainers seeking customizable and hardware-aware package builds.
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
KPort consists of several components designed to manage and build packages for KDE Neon with enhanced hardware compatibility and automation. The repository integrates Pacstall with Portage-like features, including USE flags and hardware-specific optimizations. Key workflows automate tasks such as hardware detection, syncing with GitLab, pacscript generation, and KDE Neon package updates. The directory structure organizes scripts, configuration files, and generated outputs for efficient management.

```plaintext
.
├── .github/                # GitHub workflows and CI configurations
├── bin/                    # Executable scripts for package management
├── config/                 # Configuration files for build and runtime
├── db/                     # Package database and metadata
├── dep-graph/              # Dependency graph generation and visualization
├── generated/              # Auto-generated files (e.g., pacscripts)
├── lib/                    # Shared library scripts
├── overlays/               # Custom package overlays
├── packages/               # Package definitions and metadata
├── scripts/                # Utility scripts for automation
├── vendor/                 # External dependencies and third-party tools
├── LICENSE                 # License file
├── README.md               # Project documentation
└── .gitignore              # Git ignore rules
```

Components interact via shared scripts and workflows, ensuring seamless integration between package definitions, hardware detection, and automated builds.
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
- **check-gitlab-sync.yml**: Verifies synchronization between this repository and a GitLab mirror. No secrets required.  
- **hardware-detect.yml**: Detects and logs CPU/GPU/NPU hardware compatibility for packages. Requires `HW_DETECT_API_KEY`.  
- **neon-build-ci.yml**: Builds and tests packages using KDE Neon base. Requires `NEON_CI_TOKEN`.  
- **notify-hw-detect-consumers.yml**: Sends notifications to dependent systems about updated hardware compatibility data. Requires `NOTIFY_API_KEY`.  
- **pacscript-ci.yml**: Validates and tests generated pacscripts for correctness. No secrets required.  
- **update-kde-builder-vendor.yml**: Updates vendor dependencies for KDE Neon package building. Requires `VENDOR_UPDATE_TOKEN`.  
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
[@Interested-Deving-1896](https://github.com/Interested-Deving-1896): 348 commits

*Note: This repository is a mirror. For the upstream source, refer to the original repository.*
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->

KPort is an original project — a Portage-inspired package repository for KDE Neon using Pacstall.
It was created from the following upstream inspirations:

| Origin | Host | Fork in I-D-1896 |
|--------|------|-----------------|
| [KDE/neon-neon-repositories](https://github.com/KDE/neon-neon-repositories) | GitHub | ✅ |
| [neon/ubuntu-core](https://invent.kde.org/neon/ubuntu-core) | KDE Invent | ✅ |
| [neon/pkg-kde-tools](https://invent.kde.org/neon/pkg-kde-tools) | KDE Invent | ✅ |
| [neon/pkg-kde-jenkins](https://invent.kde.org/neon/pkg-kde-jenkins) | KDE Invent | ✅ |
| [neon/pkg-kde-dev-scripts](https://invent.kde.org/neon/pkg-kde-dev-scripts) | KDE Invent | ✅ |
| [neon/docker-images](https://invent.kde.org/neon/docker-images) | KDE Invent | ✅ |
| [neon/qt-kde-team.pages.debian.net](https://invent.kde.org/neon/qt-kde-team.pages.debian.net) | KDE Invent | ✅ |
| [gentoo/portage](https://github.com/gentoo/portage) | GitHub | ✅ |
| [pacstall/pacstall](https://github.com/pacstall/pacstall) | GitHub | ✅ |
| [KDE/craft](https://github.com/KDE/craft) | GitHub | ✅ |
| [KDE/craft-blueprints-kde](https://github.com/KDE/craft-blueprints-kde) | GitHub | ✅ |
| [KDE/craft-blueprints-community](https://github.com/KDE/craft-blueprints-community) | GitHub | ✅ |
| [KDE/kde-builder](https://github.com/KDE/kde-builder) | GitHub | ✅ |
| [KDE/kdesrc-build](https://github.com/KDE/kdesrc-build) | GitHub | ✅ |
| [KDE/kde-build-metadata](https://github.com/KDE/kde-build-metadata) | GitHub | ✅ |
| [KDE/kdevplatform](https://github.com/KDE/kdevplatform) | GitHub | ✅ |
| [KDE/superbuild](https://github.com/KDE/superbuild) | GitHub | ✅ |
| [KDE/android-builder](https://github.com/KDE/android-builder) | GitHub | ✅ |
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
| File | Description |
|---|---|
| [dep-graph/origins.md](https://github.com/Interested-Deving-1896/KPort/blob/main/dep-graph/origins.md) | Dependency graph (Markdown table) |
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
[MIT](https://github.com/Interested-Deving-1896/KPort/blob/main/LICENSE) © 2026 [Interested-Deving-1896](https://github.com/Interested-Deving-1896)
<!-- AI:end:license -->
