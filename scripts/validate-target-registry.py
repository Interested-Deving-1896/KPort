#!/usr/bin/env python3
"""Validate KPort's Windows/ReactOS target registry using the Python stdlib."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

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
ALLOWED_OS = {"windows", "reactos"}
ALLOWED_ARCH = {"x86_64", "arm64", "x86"}
TOP_LEVEL_KEYS = {
    "$schema", "schema_version", "project", "purpose", "operations",
    "evidence_states", "targets", "policy", "integration",
}
POLICY_KEYS = {
    "windows_support_does_not_imply_reactos_support",
    "cross_compile_does_not_imply_runtime_compatibility",
    "unsigned_untrusted_pr_artifacts_only",
    "signing_requires_protected_release_workflow",
    "publish_from_untrusted_pull_requests",
}
INTEGRATION_KEYS = {"repository", "role", "reactos_profile"}


def fail(message: str) -> None:
    raise ValueError(message)


def _require_keys(value: dict[str, Any], required: set[str], where: str) -> None:
    missing = required - value.keys()
    extra = value.keys() - required
    if missing:
        fail(f"{where}: missing required keys: {', '.join(sorted(missing))}")
    if extra:
        fail(f"{where}: unexpected keys: {', '.join(sorted(extra))}")


def validate_registry(data: dict[str, Any], schema: dict[str, Any]) -> None:
    """Validate the registry contract and its safety invariants.

    This is a dependency-free contract validator, not a general JSON Schema engine.
    """
    if not isinstance(data, dict):
        fail("registry root must be an object")
    _require_keys(data, TOP_LEVEL_KEYS, "registry")
    if data["$schema"] != "./windows-reactos.schema.json":
        fail("registry must reference ./windows-reactos.schema.json")
    if not isinstance(schema, dict) or schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        fail("schema must declare JSON Schema draft 2020-12")
    if data["schema_version"] != "1.0.0" or data["project"] != "KPort":
        fail("unexpected registry schema_version or project")
    if not isinstance(data["purpose"], str) or not data["purpose"].strip():
        fail("purpose must be a non-empty string")

    for key, allowed in (("operations", ALLOWED_OPERATIONS), ("evidence_states", ALLOWED_EVIDENCE)):
        values = data[key]
        if not isinstance(values, list) or not values or len(values) != len(set(values)):
            fail(f"{key} must be a non-empty array of unique values")
        if not set(values) <= allowed:
            fail(f"{key} contains an unknown value")

    targets = data["targets"]
    if not isinstance(targets, list) or not targets:
        fail("targets must be a non-empty array")
    ids: list[str] = []
    required_target_keys = {
        "id", "os", "architecture", "compiler", "build_system", "status",
        "package_formats", "optional_package_formats", "test_requirements", "notes",
    }
    for index, target in enumerate(targets):
        where = f"targets[{index}]"
        if not isinstance(target, dict):
            fail(f"{where} must be an object")
        _require_keys(target, required_target_keys, where)
        target_id = target["id"]
        if not isinstance(target_id, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", target_id):
            fail(f"{where}: invalid target id")
        ids.append(target_id)
        if target["os"] not in ALLOWED_OS or target["architecture"] not in ALLOWED_ARCH:
            fail(f"{target_id}: unsupported OS or architecture")
        if target["status"] not in ALLOWED_STATES:
            fail(f"{target_id}: invalid status")
        for key in ("compiler", "build_system", "notes"):
            if not isinstance(target[key], str) or (key != "notes" and not target[key].strip()):
                fail(f"{target_id}: {key} must be a non-empty string")
        for key in ("package_formats", "optional_package_formats", "test_requirements"):
            values = target[key]
            if not isinstance(values, list) or len(values) != len(set(values)):
                fail(f"{target_id}: {key} must be a unique array")
        formats = target["package_formats"]
        optional = target["optional_package_formats"]
        if not set(formats + optional) <= ALLOWED_FORMATS:
            fail(f"{target_id}: unknown package format")
        if set(formats) & set(optional):
            fail(f"{target_id}: format cannot be both required and optional")
        if not target["test_requirements"] or not all(isinstance(x, str) and x.strip() for x in target["test_requirements"]):
            fail(f"{target_id}: test_requirements must contain non-empty strings")
        if target["os"] == "reactos" and target["architecture"] == "arm64":
            fail(f"{target_id}: ReactOS ARM64 is not an established target")
        if target["os"] == "reactos" and target["status"] == "supported":
            fail(f"{target_id}: ReactOS support requires separate runtime evidence")
    if len(ids) != len(set(ids)):
        fail("target IDs must be unique")

    policy = data["policy"]
    if not isinstance(policy, dict):
        fail("policy must be an object")
    _require_keys(policy, POLICY_KEYS, "policy")
    for key in POLICY_KEYS - {"publish_from_untrusted_pull_requests"}:
        if policy[key] is not True:
            fail(f"policy.{key} must be true")
    if policy["publish_from_untrusted_pull_requests"] is not False:
        fail("publishing from untrusted pull requests must remain disabled")

    integration = data["integration"]
    if not isinstance(integration, dict):
        fail("integration must be an object")
    _require_keys(integration, INTEGRATION_KEYS, "integration")
    if integration["repository"] != "Interested-Deving-1896/incus-windows-toolkit":
        fail("unexpected Incus Windows Toolkit integration repository")
    if not isinstance(integration["role"], list) or not integration["role"] or not all(isinstance(x, str) and x.strip() for x in integration["role"]):
        fail("integration.role must be a non-empty string array")
    if not isinstance(integration["reactos_profile"], str) or not integration["reactos_profile"].strip():
        fail("integration.reactos_profile must be a non-empty string")


def main() -> int:
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    validate_registry(data, schema)
    print(f"Validated {len(data['targets'])} target profiles against the registry contract")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, json.JSONDecodeError, ValueError, TypeError) as exc:
        print(f"Target registry validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
