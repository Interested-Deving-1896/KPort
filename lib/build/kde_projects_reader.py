# KPort KDE projects reader
#
# Adapted from vendor/kde-builder/kde_builder_lib/metadata/kde_projects_reader.py
# Original authors: Michael Pyne <mpyne@kde.org>, Andrew Shark <ashark@linuxcomp.ru>
# Original license: GPL-2.0-or-later
#
# Differences from upstream:
#   - Returns plain dicts rather than kde-builder Module objects
#   - Adds use_flags field populated from KPort overlay metadata
#   - Reads from local repo-metadata checkout or fetches via raw.githubusercontent.com
#   - No dependency on kde-builder's BuildContext

from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path
from typing import Optional


# KDE repo-metadata is a separate repo containing YAML project definitions.
# Raw URL for the projects.json file (pre-generated from YAML by KDE CI).
_PROJECTS_JSON_URL = (
    "https://invent.kde.org/sysadmin/repo-metadata/-/raw/master/projects-invent.json"
)

# Fallback: raw.githubusercontent.com mirror (if invent.kde.org is unreachable)
_PROJECTS_JSON_FALLBACK = (
    "https://raw.githubusercontent.com/KDE/repo-metadata/master/projects-invent.json"
)


class KDEProjectsReader:
    """
    Reads KDE project metadata and returns a dict suitable for ModuleResolver.

    The returned dict maps full_path -> {
        "repo_url":     str,
        "branch":       str,
        "dependencies": [str, ...],
        "use_flags":    [str, ...],   # KPort extension
        "description":  str,
    }
    """

    def __init__(
        self,
        metadata_path: Optional[Path] = None,
        kport_overlay_path: Optional[Path] = None,
    ):
        """
        Args:
            metadata_path: Path to a local repo-metadata checkout containing
                           projects-invent.json. If None, fetches from KDE invent.
            kport_overlay_path: Path to a KPort overlay JSON file that adds
                                use_flags and overrides to specific modules.
                                Format: { "full/path": { "use_flags": [...] } }
        """
        self._metadata_path = metadata_path
        self._overlay_path = kport_overlay_path
        self._repositories: Optional[dict] = None

    @property
    def repositories(self) -> dict:
        """Lazy-loaded repository dict. Fetches/parses on first access."""
        if self._repositories is None:
            self._repositories = self._load()
        return self._repositories

    def _load(self) -> dict:
        raw = self._fetch_projects_json()
        overlay = self._load_overlay()
        return self._parse(raw, overlay)

    def _fetch_projects_json(self) -> list:
        if self._metadata_path:
            p = self._metadata_path / "projects-invent.json"
            if p.exists():
                return json.loads(p.read_text())

        # Try KDE invent first, fall back to GitHub mirror
        for url in (_PROJECTS_JSON_URL, _PROJECTS_JSON_FALLBACK):
            try:
                with urllib.request.urlopen(url, timeout=15) as r:
                    return json.loads(r.read())
            except Exception:
                continue

        raise RuntimeError(
            "Could not fetch KDE projects metadata from invent.kde.org or GitHub. "
            "Pass metadata_path= pointing to a local repo-metadata checkout."
        )

    def _load_overlay(self) -> dict:
        if self._overlay_path and self._overlay_path.exists():
            return json.loads(self._overlay_path.read_text())
        return {}

    def _parse(self, projects: list, overlay: dict) -> dict:
        result = {}

        for project in projects:
            full_path = project.get("identifier", "")
            if not full_path:
                continue

            # Construct invent.kde.org clone URL
            repo_url = f"https://invent.kde.org/{full_path}.git"

            # Default branch from metadata or fall back to master
            branch = project.get("default_branch") or "master"

            # Dependencies: kde-builder stores these as a list of identifiers
            dependencies = project.get("dependencies", [])

            # Description
            description = project.get("description", "")

            entry = {
                "repo_url":     repo_url,
                "branch":       branch,
                "dependencies": dependencies,
                "use_flags":    [],
                "description":  description,
            }

            # Apply KPort overlay (use_flags, branch overrides, etc.)
            if full_path in overlay:
                entry.update(overlay[full_path])

            result[full_path] = entry

        return result

    def find(self, name: str) -> Optional[dict]:
        """
        Look up a module by short name or full path.
        Returns the first match or None.
        """
        repos = self.repositories

        # Exact full path match
        if name in repos:
            return repos[name]

        # Short name match (last path component)
        for full_path, info in repos.items():
            if full_path.split("/")[-1] == name:
                return {**info, "_full_path": full_path}

        return None
