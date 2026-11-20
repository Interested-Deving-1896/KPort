#!/usr/bin/env python3
"""Validate KPort's versioned Debian-family profile input without host mutation."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_VERSION = 1
DISTRIBUTIONS = {"debian", "devuan", "ubuntu", "kde-neon"}
SUPPORT_STATES = {"upstream-supported", "source-available", "buildable", "tested", "unavailable", "unverified"}
OPERATIONS = {"metadata", "resolve", "build", "test", "package", "boot"}
HEX_REVISION = re.compile(r"^[0-9a-f]{40,64}$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_profile(profile: Any) -> dict[str, Any]:
    require(isinstance(profile, dict), "profile must be an object")
    required = {"schema_version", "profile_id", "distribution", "release", "architecture", "backend", "source", "support"}
    require(required <= profile.keys(), f"missing fields: {', '.join(sorted(required - profile.keys()))}")
    allowed = required | {"neon"}
    require(profile.keys() <= allowed, f"unknown fields: {', '.join(sorted(profile.keys() - allowed))}")
    require(profile["schema_version"] == SCHEMA_VERSION, "unsupported schema_version")
    require(isinstance(profile["profile_id"], str) and re.fullmatch(r"[a-z0-9][a-z0-9._-]{1,127}", profile["profile_id"]) is not None, "invalid profile_id")

    distro = profile["distribution"]
    require(isinstance(distro, dict) and set(distro) == {"family", "id"}, "distribution must contain only family and id")
    require(distro["family"] == "debian-family" and distro["id"] in DISTRIBUTIONS, "unsupported distribution identity")

    release = profile["release"]
    require(isinstance(release, dict) and set(release) == {"id", "status"}, "release must contain id and status")
    require(isinstance(release["id"], str) and release["id"], "release.id must be non-empty")
    require(release["status"] in {"supported", "oldstable", "stable", "testing", "unstable", "lts", "eol", "unknown"}, "invalid release.status")

    arch = profile["architecture"]
    require(isinstance(arch, dict) and set(arch) == {"id", "aliases"}, "architecture must contain id and aliases")
    require(isinstance(arch["id"], str) and re.fullmatch(r"[a-z0-9][a-z0-9_-]*", arch["id"]) is not None, "invalid architecture.id")
    require(isinstance(arch["aliases"], list) and all(isinstance(x, str) and x for x in arch["aliases"]), "architecture.aliases must be a string array")
    require(len(set(arch["aliases"])) == len(arch["aliases"]), "duplicate architecture alias")
    require(not (arch["id"] == "i386" and "i686" in arch["aliases"]) and not (arch["id"] == "i686" and "i386" in arch["aliases"]), "i386 and i686 must remain distinct absent an authoritative mapping")

    backend = profile["backend"]
    require(isinstance(backend, dict) and backend.get("kind") in {"apt", "pacstall"}, "backend.kind must be apt or pacstall")
    require(set(backend) <= {"kind", "repositories"}, "unknown backend fields")
    if backend["kind"] == "apt":
        repos = backend.get("repositories")
        require(isinstance(repos, list) and repos, "APT backend requires repositories")
        for repo in repos:
            fields = {"id", "uri", "suite", "components", "architectures", "keyring", "metadata_policy"}
            require(isinstance(repo, dict) and set(repo) == fields, "APT repository has missing or unknown fields")
            require(all(isinstance(repo[k], str) and repo[k] for k in ("id", "uri", "suite", "keyring")), "APT repository identity, URI, suite and keyring are required")
            require(repo["uri"].startswith("https://"), "APT repository URI must use HTTPS")
            require(repo["metadata_policy"] == "signed-inrelease-or-release-gpg-sha256", "unsupported or weak APT metadata policy")
            require(isinstance(repo["components"], list) and repo["components"], "APT repository components must be non-empty")
            require(isinstance(repo["architectures"], list) and repo["architectures"], "APT repository architectures must be non-empty")
    else:
        require("repositories" not in backend, "Pacstall profiles must not declare APT repositories")

    source = profile["source"]
    require(isinstance(source, dict) and set(source) <= {"revision", "uri"} and "revision" in source, "source requires revision and optional uri")
    require(isinstance(source["revision"], str) and HEX_REVISION.fullmatch(source["revision"]) is not None, "source.revision must be a pinned git SHA or digest")
    if "uri" in source:
        require(isinstance(source["uri"], str) and source["uri"].startswith("https://"), "source.uri must use HTTPS")

    support = profile["support"]
    require(isinstance(support, dict) and set(support) == {"state", "evidence"}, "support must contain state and evidence")
    require(support["state"] in SUPPORT_STATES, "invalid support.state")
    require(isinstance(support["evidence"], list), "support.evidence must be an array")
    for item in support["evidence"]:
        require(isinstance(item, dict) and set(item) == {"operation", "artifact", "result", "reference"}, "support evidence has missing or unknown fields")
        require(item["operation"] in OPERATIONS and item["result"] in {"pass", "fail", "not-run"}, "invalid support evidence operation/result")
        require(all(isinstance(item[k], str) and item[k] for k in ("artifact", "reference")), "support evidence artifact/reference must be non-empty")

    if distro["id"] == "kde-neon":
        neon = profile.get("neon")
        require(isinstance(neon, dict) and set(neon) == {"ubuntu_base_release", "overlay"}, "KDE Neon requires an explicit Ubuntu base and overlay")
        require(all(isinstance(neon[k], str) and neon[k] for k in neon), "KDE Neon base and overlay must be non-empty")
        require(backend["kind"] == "apt", "KDE Neon profile must use its declared APT base backend")
    else:
        require("neon" not in profile, "neon metadata is valid only for kde-neon")
    return profile


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profile", type=Path, help="JSON profile file")
    args = parser.parse_args()
    try:
        with args.profile.open(encoding="utf-8") as stream:
            profile = json.load(stream)
        validate_profile(profile)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"profile validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"valid Debian-family profile: {profile['profile_id']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
