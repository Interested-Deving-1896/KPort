#!/usr/bin/env bash
# kport upgrade
#
# Rebuilds world set packages that have a newer version available or whose
# resolved USE flags have changed since the last build.
#
# Usage: kport upgrade [options]
#
# Options:
#   --ask          Show upgrade plan and confirm (default)
#   --no-ask       Upgrade without confirmation
#   --dry-run      Show what would be upgraded without doing it
#   --direct       Build without pacstall sandbox (passed through to install)
#   --depclean     After upgrade check, report installed packages no longer
#                  needed (not in world set and not in any world dep tree)
#   --use-changed  Only rebuild packages whose USE flags changed (skip version bumps)
#   --version-only Only rebuild packages with a newer version (skip USE changes)
#   --help

set -uo pipefail

source "${KPORT_LIB}/resolve.sh"

# ── Parse args ────────────────────────────────────────────────────────────────

ASK=true
DRY_RUN=false
DIRECT=false
DEPCLEAN=false
USE_CHANGED_ONLY=false
VERSION_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ask)          ASK=true;              shift ;;
    --no-ask)       ASK=false;             shift ;;
    --dry-run)      DRY_RUN=true;          shift ;;
    --direct)       DIRECT=true;           shift ;;
    --depclean)     DEPCLEAN=true;         shift ;;
    --use-changed)  USE_CHANGED_ONLY=true; shift ;;
    --version-only) VERSION_ONLY=true;     shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    -*) kport_die "Unknown option: $1" ;;
    *)  kport_die "Unexpected argument: $1" ;;
  esac
done

# ── Depclean helper ───────────────────────────────────────────────────────────
# Prints installed packages that are not in the world set and not in the
# resolved dep tree of any world package. These are orphaned deps.

_kport_run_depclean() {
  [[ -f "$KPORT_DB_WORLD" ]] || return 0

  mapfile -t world_pkgs < <(awk -F/ '{print $NF}' "$KPORT_DB_WORLD")
  [[ ${#world_pkgs[@]} -eq 0 ]] && return 0

  # Build the full set of packages needed by the world set
  local -A needed=()
  export KPORT_RESOLVE_ALL=true
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && needed["$pkg"]=1
  done < <(kport_resolve "${world_pkgs[@]}" 2>/dev/null)
  unset KPORT_RESOLVE_ALL

  # Also mark world packages themselves as needed
  for pkg in "${world_pkgs[@]}"; do
    needed["$pkg"]=1
  done

  # Find installed packages not in the needed set
  local -a orphans=()
  while IFS= read -r -d '' installed_dir; do
    local ipkg
    ipkg=$(basename "$installed_dir")
    [[ -z "${needed[$ipkg]:-}" ]] && orphans+=("$ipkg")
  done < <(find "$KPORT_DB_INSTALLED" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

  if [[ ${#orphans[@]} -eq 0 ]]; then
    kport_info "No orphaned packages found."
    return 0
  fi

  kport_header "Orphaned packages (${#orphans[@]}) — not needed by any world package"
  for pkg in "${orphans[@]}"; do
    local ver category
    ver=$(kport_db_read "$pkg" version)
    category=$(kport_db_read "$pkg" category)
    printf "  ${C_BOLD}%-30s${C_RESET} ${C_DIM}%-12s  %s${C_RESET}\n" "$pkg" "$ver" "$category"
  done
  echo ""
  kport_info "Remove with: kport remove ${orphans[*]}"
}

# ── Read world set ────────────────────────────────────────────────────────────

[[ -f "$KPORT_DB_WORLD" ]] || { kport_info "World set is empty — nothing to upgrade."; exit 0; }

mapfile -t world_entries < "$KPORT_DB_WORLD"
[[ ${#world_entries[@]} -eq 0 ]] && { kport_info "World set is empty — nothing to upgrade."; exit 0; }

# ── Check each world package for upgrades ────────────────────────────────────

declare -a to_upgrade=()
declare -A upgrade_reason=()

kport_header "Checking world set (${#world_entries[@]} package(s))"

for entry in "${world_entries[@]}"; do
  [[ -z "$entry" ]] && continue
  # entry format: category/pkgname
  pkgname="${entry##*/}"

  pacscript=$(kport_find_pacscript "$pkgname") || {
    kport_warn "  ${pkgname}: pacscript not found — skipping"
    continue
  }

  avail_ver=$(kport_pacscript_var "$pacscript" pkgver)
  inst_ver=$(kport_db_read "$pkgname" version)
  inst_use=$(kport_db_read "$pkgname" use_flags)

  # Compute current resolved USE flags.
  # KUSE must be declared inside the subshell — env var assignments on bash -c
  # only set scalars, not arrays, so we serialize the array into the script body.
  mapfile -t kuse_arr < <(kport_pacscript_array "$pacscript" KUSE)
  printf -v kuse_decl 'KUSE=(%s)' "$(printf '"%s" ' "${kuse_arr[@]}")"
  current_use=$(pkgname="$pkgname" KPORT_CONF_DIR="$KPORT_CONF" \
    bash -c "${kuse_decl}; source \"\${KPORT_LIB}/use-helpers.sh\" && use_active_flags" 2>/dev/null \
    | tr '\n' ' ' | sed 's/ $//')

  reason=""
  needs_upgrade=false

  # Version check
  if [[ "$avail_ver" != "$inst_ver" ]] && [[ "$USE_CHANGED_ONLY" != "true" ]]; then
    reason="version ${inst_ver} → ${avail_ver}"
    needs_upgrade=true
  fi

  # USE flag check
  if [[ "$current_use" != "$inst_use" ]] && [[ "$VERSION_ONLY" != "true" ]]; then
    use_reason="USE flags changed"
    reason="${reason:+${reason}, }${use_reason}"
    needs_upgrade=true
  fi

  if [[ "$needs_upgrade" == "true" ]]; then
    to_upgrade+=("$pkgname")
    upgrade_reason["$pkgname"]="$reason"
    echo -e "  ${C_BOLD}${pkgname}${C_RESET}  ${C_YELLOW}${reason}${C_RESET}"
  else
    kport_verbose "  ${pkgname}: up to date (${avail_ver})"
  fi
done

echo ""

if [[ ${#to_upgrade[@]} -eq 0 ]]; then
  kport_info "All world packages are up to date."
  # Still run depclean if requested
  if [[ "$DEPCLEAN" == "true" ]]; then
    _kport_run_depclean
  fi
  exit 0
fi

# ── Resolve full upgrade order (including deps) ───────────────────────────────

kport_header "Upgrade plan"
export KPORT_RESOLVE_ALL=true
kport_resolve_print_plan "${to_upgrade[@]}" || exit 0
mapfile -t upgrade_order < <(kport_resolve "${to_upgrade[@]}")

if [[ "$DRY_RUN" == "true" ]]; then
  kport_info "Dry run — nothing will be upgraded."
  [[ "$DEPCLEAN" == "true" ]] && _kport_run_depclean
  exit 0
fi

if [[ "$ASK" == "true" ]]; then
  kport_confirm "Proceed with upgrade?" || { kport_info "Aborted."; exit 0; }
fi

# ── Delegate to install --rebuild ─────────────────────────────────────────────

install_args=(--no-ask --rebuild)
[[ "$DIRECT" == "true" ]] && install_args+=(--direct)

if [[ "$DEPCLEAN" == "true" ]]; then
  # Run install first, then depclean after it completes
  bash "${KPORT_LIB}/cmd/install.sh" "${install_args[@]}" "${upgrade_order[@]}"
  _kport_run_depclean
else
  exec bash "${KPORT_LIB}/cmd/install.sh" "${install_args[@]}" "${upgrade_order[@]}"
fi
