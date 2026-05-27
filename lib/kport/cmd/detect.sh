#!/usr/bin/env bash
# kport detect
#
# Detects CPU, GPU, and NPU hardware and writes ~/.config/kport/hardware.conf.
#
# Usage: kport detect [options]
#
# Options:
#   --dry-run       Show what would be written without writing
#   --show-flags    Print derived USE flags after detection
#   --update        Re-run detection and update existing hardware.conf
#   --help

set -uo pipefail

# shellcheck source=lib/kport/devuan.sh
source "${KPORT_LIB}/devuan.sh"

# ── Parse args ────────────────────────────────────────────────────────────────

DRY_RUN=false
SHOW_FLAGS=false
UPDATE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true;    shift ;;
    --show-flags) SHOW_FLAGS=true; shift ;;
    --update)     UPDATE=true;     shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) kport_die "Unknown option: $1" ;;
  esac
done

# ── Check existing hardware.conf ──────────────────────────────────────────────

if [[ -f "$KPORT_HW_CONF" && "$UPDATE" != "true" && "$DRY_RUN" != "true" ]]; then
  kport_info "hardware.conf already exists: ${KPORT_HW_CONF}"
  kport_info "Use --update to re-run detection, or --show-flags to see current flags."
  echo ""
  kport_kv "CPU_TIER"   "$(kport_hw_read CPU_TIER)"
  kport_kv "GPU_TIER"   "$(kport_hw_read GPU_TIER)"
  kport_kv "NPU_TIER"   "$(kport_hw_read NPU_TIER)"
  kport_kv "INIT"       "$(kport_detect_init)"
  kport_kv "CHANNEL"    "$(kport_effective_channel)"
  exit 0
fi

# ── Run detection ─────────────────────────────────────────────────────────────

DETECT_SCRIPT="${KPORT_ROOT}/scripts/kport/kport-detect.sh"
[[ -f "$DETECT_SCRIPT" ]] || kport_die "Detection script not found: ${DETECT_SCRIPT}"

kport_info "Running hardware detection..."
echo ""

# kport-detect.sh writes to stdout; we capture and optionally write to file
local_args=()
[[ "$DRY_RUN"    == "true" ]] && local_args+=(--dry-run)
[[ "$SHOW_FLAGS" == "true" ]] && local_args+=(--show-flags)

if [[ "$DRY_RUN" == "true" ]]; then
  KPORT_CONFIG_DIR="$KPORT_CONF" bash "$DETECT_SCRIPT" "${local_args[@]}"
  kport_kv "INIT"    "$(kport_detect_init)"
  kport_kv "CHANNEL" "$(kport_effective_channel)"
else
  mkdir -p "$KPORT_CONF"
  KPORT_CONFIG_DIR="$KPORT_CONF" bash "$DETECT_SCRIPT" "${local_args[@]}"

  # Append init system info to hardware.conf
  local init_sys
  init_sys="$(kport_detect_init)"
  {
    echo ""
    echo "# Init system (detected by kport detect)"
    echo "INIT_SYSTEM=\"${init_sys}\""
    echo "KPORT_EFFECTIVE_CHANNEL=\"$(kport_effective_channel)\""
  } >> "$KPORT_HW_CONF"

  kport_info "Written: ${KPORT_HW_CONF}"
  kport_kv "INIT"    "$init_sys"
  kport_kv "CHANNEL" "$(kport_effective_channel)"

  if ! kport_is_systemd; then
    kport_warn "Non-systemd init detected (${init_sys})"
    kport_warn "  Some KDE Neon packages are systemd-dependent and will be masked or substituted."
    kport_warn "  Run 'kport install' normally — substitutions are applied automatically."
  fi
fi

# ── Show derived USE flags ────────────────────────────────────────────────────

if [[ "$SHOW_FLAGS" == "true" && -f "$KPORT_HW_CONF" ]]; then
  echo ""
  kport_header "Derived USE flags"

  # Source use-helpers with an empty KUSE to see hardware-only flags
  KUSE=() KPORT_CONF_DIR="$KPORT_CONF" \
    source "${KPORT_LIB}/use-helpers.sh" 2>/dev/null || true

  use_active_flags | while read -r flag; do
    echo -e "  ${C_GREEN}+${C_RESET}${flag}"
  done
fi
