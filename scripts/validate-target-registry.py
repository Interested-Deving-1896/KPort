#!/usr/bin/env python3
"""Validate KPort's Windows/ReactOS target registry without third-party dependencies."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "config/targets/windows-reactos.json"
SCHEMA = ROOT / "config/targets/windows-reactos.schema.json"

ALLOWED_STATES = {
    "planned", "candidate", "experimental", "build-passed",
    "package-passed", "runtime-tested", "supported", "unsupported", "unknown",
}
ALLOWED_FORMATS = {"portable-zip", "nsis-exe", "exe-installer", "msi-wix", "appx-msix"}
ALLOWED_OPERATIONS = {"native-build", "cross-build", "cross-compile", "repackage-export"}
ALLOWED_EVIDENCE = {
    "planned", "candidate", "build-passed", "package-passed",
    "runtime-tested", "supported", "unsupported", "unknown",
}


def fail(message: str) -> None:
    raise ValueError(message)


def main() -> int:
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))

    if data.get("$schema") != "./windows-reactos.schema.json":
        fail("registry must reference ./windows-reactos.schema.json")
    if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        fail("schema must declare JSON Schema draft 2020-12")
    if data.get("schema_version") != "1.0.0" or data.get("project") != "KPort":
        fail("unexpected registry schema_version or project")
    if not set(data.get("operations", [])) <= ALLOWED_OPERATIONS:
        fail("registry contains an unknown build operation")
    if not set(data.get("evidence_states", [])) <= ALLOWED_EVIDENCE:
        fail("registry contains an unknown evidence state")

    targets = data.get("targets")
    if not isinstance(targets, list) or not targets:
        fail("targets must be a non-empty array")
    ids = [target.get("id") for target in targets]
    if len(ids) != len(set(ids)):
        fail("target IDs must be unique")

    for target in targets:
        if target.get("status") not in ALLOWED_STATES:
            fail(f"{target.get('id')}: invalid status")
        formats = target.get("package_formats", [])
        optional = target.get("optional_package_formats", [])
        if not set(formats + optional) <= ALLOWED_FORMATS:
            fail(f"{target.get('id')}: unknown package format")
        if set(formats) & set(optional):
            fail(f"{target.get('id')}: format cannot be both required and optional")
        if target.get("os") == "reactos" and target.get("status") == "supported":
            fail(f"{target.get('id')}: ReactOS cannot be promoted without runtime evidence")
        if target.get("os") == "reactos" and target.get("architecture") == "arm64":
            fail(f"{target.get('id')}: ReactOS ARM64 is not an established target")

    policy = data.get("policy", {})
    if policy.get("windows_support_does_not_imply_reactos_support") is not True:
        fail("Windows and ReactOS evidence must remain independent")
    if policy.get("cross_compile_does_not_imply_runtime_compatibility") is not True:
        fail("cross-compilation must not imply runtime compatibility")
    if policy.get("publish_from_untrusted_pull_requests") is not False:
        fail("publishing from untrusted pull requests must remain disabled")

    print(f"Validated {len(targets)} target profiles against {SCHEMA.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"Target registry validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
