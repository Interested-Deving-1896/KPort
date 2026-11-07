# KDE Discover integration

**Status: package-build candidate; KPort backend not implemented.**

KDE Discover is an application-management frontend maintained in this fork:

- Fork: https://github.com/Interested-Deving-1896/discover
- Upstream parent: https://github.com/KDE/discover
- Homepage: https://invent.kde.org/plasma/discover
- Observed fork version: 6.6.80
- Implementation: C++ / Qt 6 / KDE Frameworks 6

## Two separate integration tracks

### 1. Package Discover with KPort

KPort can eventually provide a reviewed Pacscript for building and packaging Discover. The fork's current source revision is not yet pinned, its upstream divergence has not been audited, and a reproducible source checksum has not been recorded. Therefore this documentation does not add a production pacscript or use an unverifiable checksum.

Before promoting a recipe into `packages/gear/discover/`:

1. Pin an immutable source commit and archive digest.
2. Verify the source license and compare the fork against KDE upstream.
3. Validate the Qt 6, KF6, AppStream, QCoro, and optional backend build dependencies against KPort's supported target.
4. Build in CI without host package-manager privileges.
5. Run Discover's upstream unit tests and backend-specific tests.
6. Install into a disposable image and verify desktop metadata, QML imports, plugin discovery, and uninstall behavior.
7. Promote from `generated/` only after human review and successful package validation.

### 2. Native KPort backend for Discover

Discover's backend architecture uses separately compiled plugins. Existing backends integrate with package providers such as PackageKit, Flatpak, Snap, fwupd, rpm-ostree, and Alpine APK.

KPort is Pacstall-inspired and has its own pacscript/overlay model. It is not automatically compatible with PackageKit or any existing Discover backend. A native KPort backend is a distinct future project and requires:

- A stable KPort read-only search/query API.
- Authenticated repository metadata with signature and digest verification.
- A typed transaction protocol for install, remove, update, cancellation, progress, and errors.
- Explicit privilege escalation and authorization policy.
- Dependency/conflict resolution owned by KPort, not duplicated in Discover.
- Transaction rollback/recovery semantics and test fixtures.
- A security review preventing arbitrary pacscript execution from catalog metadata.

Until that contract exists, Discover must not scrape KPort pacscripts, call arbitrary shell commands, or treat repository metadata as executable instructions.

## Current capability state

| Capability | State |
|---|---|
| Discover project identified | Yes |
| Reproducible KPort package recipe | Not yet |
| Immutable source pin and digest | Missing |
| Native KPort Discover backend | Not implemented |
| Existing Discover PackageKit/Flatpak backends | Upstream features; target build must verify |
| Package installation through this integration | Disabled |

The existing KPort repository remains the package source of truth. Discover is a potential frontend, not a replacement package database.
