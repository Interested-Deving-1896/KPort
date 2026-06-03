# KPort dependency resolver
#
# Adapted from vendor/kde-builder/kde_builder_lib/dependency_resolver.py
# Original authors: Michael Pyne <mpyne@kde.org>, Johan Ouwerkerk <jm.ouwerkerk@gmail.com>,
#                   Andrew Shark <ashark@linuxcomp.ru>
# Original license: GPL-2.0-or-later
#
# Differences from upstream:
#   - Operates on KPortModule objects rather than kde-builder Module objects
#   - Produces a build order suitable for pacscript generation (leaf deps first)
#   - Cycle detection raises DependencyCycleError with the full cycle path
#   - Optional: prune modules not reachable from a given root set

from __future__ import annotations

from collections import defaultdict, deque
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .module_resolver import KPortModule


class DependencyResolver:
    """
    Topological sort of KPortModule dependency graphs.

    Produces a build order where each module appears after all its
    dependencies — suitable for sequential pacscript generation and
    installation ordering.

    Uses Kahn's algorithm (BFS-based topological sort) for cycle detection
    and deterministic ordering.
    """

    def __init__(self, modules: list[KPortModule]):
        """
        Args:
            modules: Full list of resolved KPortModule objects. Dependencies
                     referenced by name must be present in this list or they
                     are treated as external (already-installed) and skipped.
        """
        self._modules = {m.name: m for m in modules}
        self._full_path_index = {m.full_path: m for m in modules}

    def ordered(self, roots: list[str] | None = None) -> list[KPortModule]:
        """
        Return modules in dependency-first build order.

        Args:
            roots: Optional list of module names/full_paths to build.
                   If provided, only modules reachable from roots are included.
                   If None, all modules are ordered.

        Returns:
            List of KPortModule in build order (dependencies before dependents).

        Raises:
            DependencyCycleError: if a dependency cycle is detected.
            ModuleMissingError: if a root name is not in the module set.
        """
        if roots is not None:
            reachable = self._reachable(roots)
        else:
            reachable = set(self._modules.keys())

        # Build adjacency and in-degree for Kahn's algorithm
        in_degree: dict[str, int] = defaultdict(int)
        dependents: dict[str, list[str]] = defaultdict(list)  # dep -> [modules that need it]

        for name in reachable:
            module = self._modules[name]
            in_degree.setdefault(name, 0)
            for dep in module.dependencies:
                dep_name = self._resolve_dep_name(dep)
                if dep_name not in reachable:
                    continue  # external dep, skip
                dependents[dep_name].append(name)
                in_degree[name] += 1

        # Kahn's BFS
        queue = deque(
            sorted(name for name, deg in in_degree.items() if deg == 0)
        )
        result: list[KPortModule] = []

        while queue:
            name = queue.popleft()
            result.append(self._modules[name])
            for dependent in sorted(dependents.get(name, [])):
                in_degree[dependent] -= 1
                if in_degree[dependent] == 0:
                    queue.append(dependent)

        if len(result) != len(reachable):
            cycle = self._find_cycle(reachable, in_degree)
            raise DependencyCycleError(
                f"Dependency cycle detected: {' -> '.join(cycle)}"
            )

        return result

    def _reachable(self, roots: list[str]) -> set[str]:
        """BFS from roots to collect all transitively reachable module names."""
        visited: set[str] = set()
        queue = deque()

        for root in roots:
            name = self._resolve_dep_name(root)
            if name not in self._modules:
                raise ModuleMissingError(f"Root module '{root}' not in module set")
            queue.append(name)

        while queue:
            name = queue.popleft()
            if name in visited:
                continue
            visited.add(name)
            module = self._modules[name]
            for dep in module.dependencies:
                dep_name = self._resolve_dep_name(dep)
                if dep_name in self._modules and dep_name not in visited:
                    queue.append(dep_name)

        return visited

    def _resolve_dep_name(self, dep: str) -> str:
        """Resolve a dependency string (short name or full path) to a short name."""
        if "/" in dep:
            module = self._full_path_index.get(dep)
            return module.name if module else dep.split("/")[-1]
        return dep

    def _find_cycle(self, reachable: set[str], in_degree: dict[str, int]) -> list[str]:
        """DFS to find and return one cycle path for error reporting."""
        remaining = {n for n in reachable if in_degree.get(n, 0) > 0}
        visited: set[str] = set()
        path: list[str] = []

        def dfs(name: str) -> bool:
            if name in path:
                cycle_start = path.index(name)
                path.append(name)
                return True
            if name in visited or name not in remaining:
                return False
            visited.add(name)
            path.append(name)
            for dep in self._modules[name].dependencies:
                dep_name = self._resolve_dep_name(dep)
                if dep_name in remaining and dfs(dep_name):
                    return True
            path.pop()
            return False

        for name in sorted(remaining):
            if dfs(name):
                return path
        return list(remaining)[:3] + ["..."]


class DependencyCycleError(Exception):
    pass


class ModuleMissingError(Exception):
    pass
