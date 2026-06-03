# KPort module resolver
#
# Adapted from vendor/kde-builder/kde_builder_lib/module_resolver.py
# Original authors: Michael Pyne <mpyne@kde.org>, Andrew Shark <ashark@linuxcomp.ru>
# Original license: GPL-2.0-or-later
#
# Differences from upstream:
#   - Resolves modules to KPort pacscript targets rather than build directories
#   - Integrates USE flag filtering: modules masked by USE flags are excluded
#   - Returns KPortModule objects instead of kde-builder Module objects
#   - No dependency on kde-builder's BuildContext or OptionsBase

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class KPortModule:
    """A resolved KDE module ready for pacscript generation."""
    name: str
    full_path: str          # e.g. "kde/workspace/plasma-workspace"
    repo_url: str
    branch: str = "master"
    use_flags: list[str] = field(default_factory=list)
    dependencies: list[str] = field(default_factory=list)
    pacscript_path: Optional[str] = None

    @property
    def short_name(self) -> str:
        """Last path component — matches pacscript filename convention."""
        return self.full_path.split("/")[-1]


class ModuleResolver:
    """
    Resolves KDE module names to KPortModule objects.

    Accepts short names (e.g. 'plasma-workspace'), full paths
    (e.g. 'kde/workspace/plasma-workspace'), or glob patterns
    (e.g. 'kde/workspace/*').

    USE flag filtering is applied during resolution: if a module's
    required USE flags are not satisfied by the active flag set,
    the module is excluded from the result.
    """

    def __init__(self, project_db: dict, active_use_flags: set[str] | None = None):
        """
        Args:
            project_db: dict mapping full_path -> repo info, as returned by
                        KDEProjectsReader.repositories after loading repo-metadata.
            active_use_flags: set of active USE flags for this build context.
                              Modules requiring flags not in this set are excluded.
        """
        self._db = project_db
        self._active_flags = active_use_flags or set()

        # Build reverse index: short_name -> [full_path, ...]
        self._short_name_index: dict[str, list[str]] = {}
        for full_path in project_db:
            short = full_path.split("/")[-1]
            self._short_name_index.setdefault(short, []).append(full_path)

    def resolve(self, names: list[str]) -> list[KPortModule]:
        """
        Resolve a list of module name/glob patterns to KPortModule objects.

        Glob patterns use '*' as wildcard matching any path component.
        Short names are resolved via the reverse index; ambiguous short names
        (mapping to multiple full paths) raise ModuleAmbiguousError.
        """
        resolved: list[KPortModule] = []
        seen: set[str] = set()

        for name in names:
            for module in self._resolve_one(name):
                if module.full_path not in seen:
                    seen.add(module.full_path)
                    resolved.append(module)

        return resolved

    def _resolve_one(self, name: str) -> list[KPortModule]:
        # Glob pattern
        if "*" in name:
            return self._resolve_glob(name)

        # Full path (contains /)
        if "/" in name:
            info = self._db.get(name)
            if not info:
                raise ModuleNotFoundError(f"No KDE module at path '{name}'")
            return [self._make_module(name, info)]

        # Short name
        candidates = self._short_name_index.get(name, [])
        if not candidates:
            raise ModuleNotFoundError(f"No KDE module named '{name}'")
        if len(candidates) > 1:
            raise ModuleAmbiguousError(
                f"'{name}' matches multiple modules: {candidates}. "
                f"Use the full path to disambiguate."
            )
        full_path = candidates[0]
        return [self._make_module(full_path, self._db[full_path])]

    def _resolve_glob(self, pattern: str) -> list[KPortModule]:
        regex = re.compile(
            "^" + re.escape(pattern).replace(r"\*", "[^/]+") + "$"
        )
        results = []
        for full_path, info in self._db.items():
            if regex.match(full_path):
                results.append(self._make_module(full_path, info))
        return results

    def _make_module(self, full_path: str, info: dict) -> KPortModule:
        required_flags = set(info.get("use_flags", []))
        if not required_flags.issubset(self._active_flags):
            missing = required_flags - self._active_flags
            raise ModuleUseFlagError(
                f"Module '{full_path}' requires USE flags: {missing}"
            )
        return KPortModule(
            name=full_path.split("/")[-1],
            full_path=full_path,
            repo_url=info.get("repo_url", ""),
            branch=info.get("branch", "master"),
            use_flags=list(required_flags),
            dependencies=info.get("dependencies", []),
        )


class ModuleNotFoundError(Exception):
    pass


class ModuleAmbiguousError(Exception):
    pass


class ModuleUseFlagError(Exception):
    pass
