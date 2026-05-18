#!/usr/bin/env bash
# kport remove
#
# Uninstalls one or more packages and removes them from the database.
#
# Usage: kport remove [options] <pkgname...>
#
# Options:
#   --ask       Confirm before removing (default)
#   --no-ask    Remove without confirmation
#   --dry-run   Show what would be removed without doing it
#   --force     Skip reverse-dep safety check
#   --help

set -uo pipefail

# ── Parse args ────────────────────────────────────────────────────────────────

ASK=true
DRY_RUN=false
FORCE=false
PACKAGES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ask)     ASK=true;     shift ;;
    --no-ask)  ASK=false;    shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true;   shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    -*) kport_die "Unknown option: $1" ;;
    *)  PACKAGES+=("$1"); shift ;;
  esac
done

[[ ${#PACKAGES[@]} -eq 0 ]] && kport_die "Usage: kport remove <pkgname...>"

# ── Verify packages are installed ─────────────────────────────────────────────

to_remove=()
for pkg in "${PACKAGES[@]}"; do
  if ! kport_is_installed "$pkg"; then
    kport_warn "${pkg} is not installed — skipping"
    continue
  fi
  to_remove+=("$pkg")
done

[[ ${#to_remove[@]} -eq 0 ]] && { kport_info "Nothing to remove."; exit 0; }

# ── Reverse-dep check ─────────────────────────────────────────────────────────
# Warn if any installed package depends on a package being removed.
# Skipped with --force.

rdep_warnings=0
[[ "$FORCE" == "true" ]] && rdep_warnings=-1  # sentinel: skip check
for pkg in "${to_remove[@]}"; do
  [[ "$rdep_warnings" -eq -1 ]] && break   # --force: skip
  rdeps=()
  # Scan all installed packages for deps on $pkg
  while IFS= read -r -d '' installed_dir; do
    installed_pkg=$(basename "$installed_dir")
    # Skip packages also being removed
    local_skip=false
    for r in "${to_remove[@]}"; do
      [[ "$r" == "$installed_pkg" ]] && local_skip=true && break
    done
    [[ "$local_skip" == "true" ]] && continue

    # Find the pacscript for this installed package and check its depends
    pacscript=$(kport_find_pacscript "$installed_pkg" 2>/dev/null) || continue
    if kport_pacscript_array "$pacscript" depends 2>/dev/null | grep -qxF "$pkg"; then
      rdeps+=("$installed_pkg")
    fi
  done < <(find "$KPORT_DB_INSTALLED" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

  if [[ ${#rdeps[@]} -gt 0 ]]; then
    kport_warn "${pkg} is required by: ${rdeps[*]}"
    (( rdep_warnings++ )) || true
  fi
done

if [[ "$rdep_warnings" -gt 0 ]]; then
  kport_warn "Removing these packages may break installed packages."
  if [[ "$ASK" == "true" ]]; then
    kport_confirm "Remove anyway?" || { kport_info "Aborted."; exit 0; }
  fi
fi

# ── Show plan ─────────────────────────────────────────────────────────────────

kport_header "Remove plan (${#to_remove[@]} package(s))"
for pkg in "${to_remove[@]}"; do
  ver=$(kport_db_read "$pkg" version)
  category=$(kport_db_read "$pkg" category)
  printf "  ${C_BOLD}%-30s${C_RESET} ${C_DIM}%-12s  %s${C_RESET}\n" \
    "$pkg" "$ver" "$category"
done
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  kport_info "Dry run — nothing will be removed."
  exit 0
fi

if [[ "$ASK" == "true" ]]; then
  kport_confirm "Remove these packages?" || { kport_info "Aborted."; exit 0; }
fi

# ── Remove each package ───────────────────────────────────────────────────────

ok=0; failed=0

for pkg in "${to_remove[@]}"; do
  kport_header "Removing ${pkg}"

  category=$(kport_db_read "$pkg" category)

  # Remove installed files
  files_list="${KPORT_DB_INSTALLED}/${pkg}/files"
  if [[ -f "$files_list" ]]; then
    file_count=$(wc -l < "$files_list")
    kport_info "Removing ${file_count} files..."

    remove_failed=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ -f "$f" || -L "$f" ]]; then
        sudo rm -f "$f" || { kport_warn "Could not remove: $f"; remove_failed=1; }
      fi
    done < "$files_list"

    # Remove empty directories left behind
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      dir=$(dirname "$f")
      [[ -d "$dir" ]] && sudo rmdir --ignore-fail-on-non-empty "$dir" 2>/dev/null || true
    done < "$files_list"

    if [[ "$remove_failed" -eq 1 ]]; then
      kport_warn "Some files could not be removed (may require manual cleanup)"
    fi
  else
    kport_warn "No file list found for ${pkg} — skipping file removal"
    kport_warn "If installed via pacstall, run: pacstall -R ${pkg}"
  fi

  # Remove from database
  kport_db_remove "$pkg"
  kport_world_remove "$pkg" "$category"

  kport_info "${C_GREEN}✔${C_RESET} Removed ${pkg}"
  (( ok++ )) || true
  echo ""
done

echo ""
kport_info "Remove complete — succeeded: ${ok}  failed: ${failed}"
[[ "$failed" -gt 0 ]] && exit 1 || exit 0
