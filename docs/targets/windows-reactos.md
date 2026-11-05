# KPort Windows and ReactOS build/export targets

**Status:** architecture specification; implementation and target support are not yet verified.

This document extends the multi-target scope in [KPort issue #48](https://github.com/Interested-Deving-1896/KPort/issues/48) and is tracked by [issue #49](https://github.com/Interested-Deving-1896/KPort/issues/49).

## 1. Scope and target separation

KPort should reuse its existing KDE Neon-first package definitions, KDE Gear source metadata, dependency graph, USE flags and CPU/GPU/NPU capability contract. Windows and ReactOS are additional target adapters, not separate package repositories.

A target is not just an operating-system name. Every build plan must identify:

- build host OS and architecture;
- target OS, release/compatibility baseline and architecture;
- compiler/toolchain and ABI (MSVC, MinGW-w64, or another explicitly supported toolchain);
- Qt and KDE Frameworks versions, compiler ABI and platform plugins;
- build-time and runtime dependencies;
- packaging adapter and output format;
- signing policy, provenance and test evidence.

The target registry in `config/targets/windows-reactos.json` is an initial machine-readable planning contract. Its `planned` and `experimental` states are not claims that KPort already builds these targets.

## 2. Target profiles

| Profile | Initial intent | Toolchain direction | State |
|---|---|---|---|
| `windows-x86_64-msvc` | Main Windows desktop target | KDE Craft + MSVC, when upstream blueprints/dependencies support it | planned |
| `windows-x86_64-mingw` | Alternative Windows desktop target | KDE Craft + MinGW-w64, package-by-package | planned |
| `windows-arm64` | Windows on ARM | ARM64 toolchain and complete ARM64 dependency closure | planned |
| `reactos-x86` | Conservative Win32 application compatibility | PE/COFF x86 toolchain; MinGW-w64 is a candidate, not a blanket guarantee | experimental |

Do not infer Windows ARM64 support from x86_64 support. Do not infer ReactOS support from a Windows build. ReactOS is a separate, alpha-quality operating system with compatibility gaps; test every package/version against a pinned ReactOS image and record the result. Do not claim ReactOS ARM64 support unless the OS, toolchain and runtime are independently demonstrated.

## 3. Build and export operations

Keep these operations distinct in planner output:

1. **Native build:** build on the same OS/architecture as the target.
2. **Cross-build:** orchestrate a target build from a different host using a supported environment (for example, an Incus Windows VM).
3. **Cross-compile:** compile for a target ABI using an explicit compiler and sysroot; this does not prove the result runs.
4. **Repackage/export:** package an already-built, compatible artifact without changing its ABI or pretending it was rebuilt.

Each plan must fail closed when a required compiler, sysroot, dependency, platform plugin or ABI is unknown.

## 4. Package formats

### Windows

- **Portable bundle / ZIP:** first-class neutral export for staged application files and required runtime libraries.
- **NSIS `.exe` installer:** preferred first installer adapter because KDE Craft documents an executable installer workflow.
- **MSI:** separate adapter, initially gated behind a real WiX/MSI build and install/uninstall test. Never rename an NSIS `.exe` to `.msi` or infer MSI support from Windows compatibility.
- **APPX/MSIX:** future optional store/deployment adapter; keep distinct from EXE/MSI.

KDE Craft is the upstream build and packaging integration to investigate/reuse. Craft supports Windows builds and can create executable installers; its packaging documentation also describes KDE's Windows CI artifact and signing/publishing process. KPort should consume upstream Craft blueprints and CI conventions rather than reimplementing KDE's dependency resolver.

### ReactOS

- Begin with portable PE/COFF application bundles and ZIP exports.
- Treat EXE installer execution as a separate compatibility test.
- Treat MSI installation as experimental until the selected Windows Installer implementation and required APIs are available and verified on the pinned ReactOS version.
- Record installation, first-launch, core-function, upgrade and uninstall results separately.
- Never label a package ReactOS-compatible merely because it is a Win32 executable.

## 5. Incus Windows Toolkit integration

Use [incus-windows-toolkit](https://github.com/Interested-Deving-1896/incus-windows-toolkit) as the VM and artifact execution layer, not as KPort's package database or build engine.

Recommended integration boundaries:

- Provision isolated Windows desktop build/test VMs from toolkit profiles.
- Run KDE Craft / MSVC or MinGW builds inside the appropriate Windows guest where required.
- Stage build outputs, logs, checksums, SBOMs and provenance into a versioned artifact directory.
- Use BDFS/virtiofs only as an optional host-side staging/storage transport; it does not change the guest package format.
- Add a ReactOS VM profile to the toolkit only after a pinned, reproducible ReactOS image and compatible virtual hardware configuration are available. The current toolkit Windows profiles do not establish ReactOS support.
- Keep signing keys and release credentials outside untrusted PR jobs; signing and publication belong only to protected, reviewed release workflows.

The toolkit currently documents Windows desktop/server x86_64 profiles and a Windows desktop ARM64 profile. These are Windows VM profiles, not ReactOS profiles.

## 6. Compatibility and evidence model

Use explicit per-package, per-version, per-architecture states:

- `planned`: registry entry exists; no implementation claim.
- `candidate`: toolchain or upstream packaging route identified.
- `build-passed`: compilation completed for the exact target tuple.
- `package-passed`: artifact format generated and structurally validated.
- `runtime-tested`: install/launch/core smoke tests passed on the target OS and version.
- `supported`: maintainer-approved evidence meets the target's acceptance policy.
- `unsupported` / `unknown`: known failure or insufficient evidence.

A successful cross-compile is not a runtime test. A Windows VM test is not a ReactOS test. A test in an emulator is not proof of physical-device compatibility.

For every artifact, retain source commit, blueprint/recipe revision, compiler and version, architecture, Qt/KF ABI, dependency lock/provenance, license metadata, SBOM, SHA-256, package format, test image/version, logs and evidence status.

## 7. Initial CI and validation sequence

1. Validate the target registry and package-format schema.
2. Add deterministic planner fixtures for Windows MSVC, Windows MinGW, Windows ARM64 and ReactOS x86.
3. Reject invalid combinations (for example, MSVC ABI artifacts selected for a MinGW runtime or a Windows result promoted to ReactOS).
4. Build a small Qt/KDE fixture through Craft on a Windows VM.
5. Generate and inspect a portable bundle and NSIS EXE; verify hashes and dependency closure.
6. Add MSI only after a dedicated WiX adapter can build, install, upgrade and uninstall a fixture.
7. Add ReactOS VM tests only after a pinned image and repeatable VM profile exist; until then retain `experimental` / `candidate` status.
8. Publish nothing from untrusted pull requests. Sign only from protected release workflows.

## 8. Suggested follow-on targets

After the Windows/ReactOS foundation, consider macOS (Craft/DMG), FreeBSD (native ports/packages adapter), and generic POSIX portable bundles. Keep each OS/package manager separate. Do not conflate Android APK, Linux AppImage, Windows EXE/MSI, APPX/MSIX, FreeBSD packages or source archives.

## 9. Upstream references

- [KDE Craft: building KDE software on Windows](https://develop.kde.org/docs/getting-started/building/craft/)
- [KDE: packaging and publishing applications for Windows](https://develop.kde.org/docs/packaging/windows/packaging/)
- [KDE: Windows platform setup](https://develop.kde.org/docs/getting-started/kirigami/platforms-windows/)
- [KDE: supported build approaches](https://develop.kde.org/docs/getting-started/building/)
- [ReactOS FAQ and compatibility guidance](https://reactos.org/faq/)
- [ReactOS source and current project status](https://github.com/reactos/reactos)
- [Incus Windows Toolkit](https://github.com/Interested-Deving-1896/incus-windows-toolkit)

## 10. Non-goals for this initial specification

- Claiming all KDE Gear applications build on Windows or ReactOS.
- Treating a Windows installer as automatically ReactOS-compatible.
- Building ReactOS itself inside KPort.
- Running Windows or ReactOS builds on arbitrary Linux runners without an explicit VM/toolchain.
- Storing or exposing signing credentials in repository source or untrusted workflows.
