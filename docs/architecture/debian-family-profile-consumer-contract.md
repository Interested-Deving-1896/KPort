# Debian-family profile consumer contract

Status: proposal; read-only integration boundary. This document does not claim that any Debian-family release or architecture is currently supported by KPort.

## Ownership boundaries

- **Shared profile catalogue** owns canonical distribution IDs, release IDs, architecture identifiers and aliases, upstream provenance, support evidence, and pinned rootfs/build inputs.
- **Debian, Devuan, and Ubuntu adapters** own their native repository, package-manager, init-system, release, and package naming semantics. Similarity between distributions must not be treated as interchangeability.
- **KDE Neon edition metadata** declares its exact Ubuntu base release and Neon overlay. A Neon edition must not be inferred from a generic Debian or Ubuntu profile.
- **KPort** owns package intent, KDE component mapping, USE/hardware selection, dependency planning, Pacstall generation, and target-specific build/install adapters.
- **BDFS** validates artifact integrity, manifests, and provenance; it does not implement APT repository resolution.
- **Fork-Sync-All** may coordinate repository lifecycle and CI only through explicit authorization, source pinning, and auditable provenance.

## Consumer contract

A profile consumed by KPort should provide a stable schema version and immutable profile identifier; distribution family and exact distribution identifier; release identifier and upstream release status/provenance; architecture identifier and source-defined aliases; explicit package backend and repository metadata policy; exact source/profile revision or content digest; capability declarations and evidence scoped to a specific operation/artifact; and a support state distinguishing upstream-supported, source-available, buildable, tested, unavailable, and unverified.

The consumer must reject unknown schema versions and malformed or ambiguous identities. Aliases are normalized only at input boundaries. Canonical identifiers remain stable through planning and output. In particular, `i386` and `i686` are distinct identifiers unless an authoritative profile explicitly defines a mapping for a specific operation.

Support is not a single boolean. Evidence is scoped to `distribution × release × architecture × operation × artifact`. A successful metadata parse does not prove package installability, a successful build, or a bootable image.

## APT trust and repository safety

APT-backed profiles must identify the expected repository metadata format and trusted keyring policy. Repository metadata validation must:

1. Verify signed InRelease metadata, or the supported Release plus detached-signature form, using the profile's explicitly trusted keyring.
2. Validate authenticated hashes and sizes for acquired indexes and artifacts.
3. Fail closed on missing signatures, untrusted keys, hash mismatches, unsupported weak metadata, or ambiguous repository identity.
4. Keep suites, components, architectures, and repository origins bound to the selected distribution/release profile.
5. Never silently enable insecure repositories, downgrade authentication, mix suites, substitute another distribution, or fall back to an unrelated mirror.

HTTP reachability and cryptographic authenticity are separate results. A reachable repository is not necessarily trusted. The profile consumer is read-only during discovery and planning. It must not rewrite host APT sources, import keys into the host trust store, install packages, or mutate the host.

## Keep package workflows distinct

Pacstall remains a KPort-owned package/build workflow. It may consume a declared base profile, but Pacstall package generation and installation must not be represented as APT repository acquisition or APT dependency resolution. The plan should record which backend performs each action, and tests must ensure that a Pacstall operation cannot accidentally execute through the APT adapter (or vice versa).

## Initial adapter scope

The initial integration should be limited to explicit adapters for Debian, Devuan, and Ubuntu. KDE Neon should be represented as an explicitly based Ubuntu profile plus a separate Neon overlay/edition declaration.

Do not infer Devuan compatibility from Debian package availability. Init-system substitution and package masks require Devuan-specific evidence and remain KPort adapter policy rather than shared distribution identity.

## Validation and acceptance gates

Before enabling a profile for mutation-capable operations, add tests for:

- Schema version validation and rejection of unknown versions.
- Canonical identifiers and boundary-only alias normalization.
- Preservation of the distinction between `i386` and `i686`.
- Exact KDE Neon Ubuntu-base and overlay declarations.
- Signed InRelease and Release/signature fixtures with trusted and untrusted keys.
- Hash/size mismatch, missing signature, weak metadata, wrong-suite, and cross-origin negative fixtures.
- Explicit backend routing so Pacstall and APT operations cannot be conflated.
- Read-only discovery/planning, including proof that no host files or package state change.
- Regression coverage for existing Pacstall generation and package workflows.

Tests should use synthetic repository fixtures and test keys. Never rely on live third-party repositories as the sole security test oracle.

## Import and rollout guardrails

This contract does not authorize bulk import or consolidation of the existing Debian i386 repository set. Reconcile overlapping repositories, preserve history and attribution, pin source revisions, and repair the Fork-Sync-All import workflow's preflight, collision, partial-failure, provenance, and force-push safeguards before any import.

No package publishing, upstream writes, mirror propagation, host installation, signing-key access, or destructive operation is authorized by this proposal. Those actions require their own explicit authorization and independently passing checks.

## Suggested implementation sequence

1. Agree and version the shared profile schema in its owning repository.
2. Add a KPort read-only profile loader and strict validation tests.
3. Add synthetic signed APT metadata fixtures and backend-routing tests.
4. Connect exact Debian/Devuan/Ubuntu profiles; add Neon only with its declared Ubuntu base and overlay.
5. Enable mutation-capable adapters only after separate safety review and end-to-end tests.
