#!/usr/bin/env bash
# kport multiarch
#
# Manages dpkg foreign-architecture registration and the corresponding
# KPort overlay activation for non-native architectures.
#
# Supported foreign architectures (matching penguins-eggs release targets):
#   i386     — 32-bit x86 (default for 32-bit; Debian sid source)
#   arm64    — 64-bit ARM / AArch64 (Debian sid source)
#   riscv64  — RISC-V 64-bit (Debian ports source)
#
# Usage:
#   kport multiarch enable  <arch>   — register arch + enable overlay
#   kport multiarch disable <arch>   — deregister arch + disable overlay
#   kport multiarch list             — show registered foreign arches
#   kport multiarch status           — show all supported arches and their state
#
# The default 32-bit architecture is i386 (set in config/keywords.yml).
# Running `kport multiarch enable 32bit` is an alias for `enable i386`.

set -euo pipefail

KPORT_ROOT="${KPORT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=lib/kport/common.sh
source "${KPORT_ROOT}/lib/kport/common.sh"

# ── Supported foreign architectures ─────────────────────────────────────────
# Maps Debian arch name → overlay name → Debian source name
declare -A ARCH_OVERLAY=(
  [i386]="plasma6-i386"
  [arm64]="plasma6-arm64"
  [riscv64]="plasma6-riscv64"
)

declare -A ARCH_SOURCE=(
  [i386]="debian-sid"
  [arm64]="debian-sid"
  [riscv64]="debian-ports"
)

# Alias: "32bit" → i386 (the default 32-bit arch per keywords.yml)
resolve_arch() {
  local arch="$1"
  if [[ "${arch}" == "32bit" ]]; then
    echo "i386"
  else
    echo "${arch}"
  fi
}

# ── Subcommands ──────────────────────────────────────────────────────────────

cmd_enable() {
  local arch
  arch=$(resolve_arch "${1:-}")
  if [[ -z "${arch}" ]]; then
    die "Usage: kport multiarch enable <arch|32bit>"
  fi
  if [[ -z "${ARCH_OVERLAY[${arch}]+x}" ]]; then
    die "Unsupported architecture: ${arch}. Supported: ${!ARCH_OVERLAY[*]}"
  fi

  local native_arch
  native_arch=$(dpkg --print-architecture)
  if [[ "${arch}" == "${native_arch}" ]]; then
    info "  ${arch} is already the native architecture — nothing to do"
    return 0
  fi

  # 1. Register with dpkg
  if dpkg --print-foreign-architectures | grep -qx "${arch}"; then
    info "  dpkg: ${arch} already registered"
  else
    info "  Registering ${arch} with dpkg..."
    dpkg --add-architecture "${arch}"
    info "  Running apt-get update to fetch ${arch} package lists..."
    apt-get update -qq
  fi

  # 2. Install Debian keyring if needed (for debian-sid / debian-ports sources)
  local source="${ARCH_SOURCE[${arch}]}"
  if [[ "${source}" == "debian-ports" ]]; then
    if ! dpkg -l debian-ports-archive-keyring &>/dev/null; then
      info "  Installing debian-ports-archive-keyring..."
      apt-get install -y -qq debian-ports-archive-keyring
    fi
  else
    if ! dpkg -l debian-archive-keyring &>/dev/null; then
      info "  Installing debian-archive-keyring..."
      apt-get install -y -qq debian-archive-keyring
    fi
  fi

  # 3. Enable the KPort overlay
  local overlay="${ARCH_OVERLAY[${arch}]}"
  info "  Enabling KPort overlay: ${overlay}"
  kport_overlay_enable "${overlay}"

  info "  ✓ ${arch} multiarch enabled (overlay: ${overlay}, source: ${source})"
  info "  Run 'kport sync' to fetch package lists, then 'kport install <pkg>:${arch}'"
}

cmd_disable() {
  local arch
  arch=$(resolve_arch "${1:-}")
  if [[ -z "${arch}" ]]; then
    die "Usage: kport multiarch disable <arch|32bit>"
  fi
  if [[ -z "${ARCH_OVERLAY[${arch}]+x}" ]]; then
    die "Unsupported architecture: ${arch}"
  fi

  # 1. Disable the KPort overlay
  local overlay="${ARCH_OVERLAY[${arch}]}"
  info "  Disabling KPort overlay: ${overlay}"
  kport_overlay_disable "${overlay}"

  # 2. Remove from dpkg (only if no packages installed for this arch)
  local installed_count
  installed_count=$(dpkg --get-selections | grep ":${arch}" | wc -l || true)
  if [[ "${installed_count}" -gt 0 ]]; then
    warn "  ${installed_count} packages still installed for ${arch} — not removing from dpkg"
    warn "  Remove them first, then run: dpkg --remove-architecture ${arch}"
  else
    dpkg --remove-architecture "${arch}" 2>/dev/null || true
    info "  Removed ${arch} from dpkg foreign architectures"
  fi

  info "  ✓ ${arch} multiarch disabled"
}

cmd_list() {
  info "Native architecture: $(dpkg --print-architecture)"
  info "Foreign architectures:"
  local foreign
  foreign=$(dpkg --print-foreign-architectures)
  if [[ -z "${foreign}" ]]; then
    info "  (none)"
  else
    while IFS= read -r arch; do
      local overlay="${ARCH_OVERLAY[${arch}]:-unknown}"
      info "  ${arch}  (overlay: ${overlay})"
    done <<< "${foreign}"
  fi
}

cmd_status() {
  local native_arch
  native_arch=$(dpkg --print-architecture)
  local foreign_arches
  foreign_arches=$(dpkg --print-foreign-architectures)

  printf "%-12s %-10s %-25s %-20s\n" "ARCH" "STATUS" "OVERLAY" "SOURCE"
  printf "%-12s %-10s %-25s %-20s\n" "----" "------" "-------" "------"

  # Native arch
  printf "%-12s %-10s %-25s %-20s\n" \
    "${native_arch}" "native" "(main tree)" "kde-neon / debian-sid"

  # All supported foreign arches
  for arch in i386 arm64 riscv64; do
    local status="disabled"
    if echo "${foreign_arches}" | grep -qx "${arch}"; then
      status="enabled"
    fi
    local overlay="${ARCH_OVERLAY[${arch}]}"
    local source="${ARCH_SOURCE[${arch}]}"
    # Mark i386 as the default 32-bit
    local label="${arch}"
    [[ "${arch}" == "i386" ]] && label="i386 (32bit)"
    printf "%-12s %-10s %-25s %-20s\n" "${label}" "${status}" "${overlay}" "${source}"
  done
}

# ── Overlay enable/disable helpers ──────────────────────────────────────────
# These manipulate the enabled: field in config/repositories.yml.
# A proper implementation would use a YAML parser; this uses sed for portability.

kport_overlay_enable() {
  local name="$1"
  local config="${KPORT_ROOT}/config/repositories.yml"
  # Find the overlay block and set enabled: true
  python3 - "${config}" "${name}" "true" << 'PYEOF'
import sys, re

config_path, overlay_name, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(config_path) as f:
    content = f.read()

# Find the overlay block by name and update its enabled field
pattern = r'(- name: ' + re.escape(overlay_name) + r'.*?enabled:)\s*(true|false)'
replacement = r'\1 ' + value
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
with open(config_path, 'w') as f:
    f.write(new_content)
print(f"  Set {overlay_name} enabled={value}")
PYEOF
}

kport_overlay_disable() {
  kport_overlay_enable "$1"  # reuse with "false" — caller sets value
  # Actually call with false
  local name="$1"
  local config="${KPORT_ROOT}/config/repositories.yml"
  python3 - "${config}" "${name}" "false" << 'PYEOF'
import sys, re
config_path, overlay_name, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(config_path) as f:
    content = f.read()
pattern = r'(- name: ' + re.escape(overlay_name) + r'.*?enabled:)\s*(true|false)'
replacement = r'\1 ' + value
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
with open(config_path, 'w') as f:
    f.write(new_content)
PYEOF
}

# ── Dispatch ─────────────────────────────────────────────────────────────────
SUBCOMMAND="${1:-status}"
shift || true

case "${SUBCOMMAND}" in
  enable)   cmd_enable  "${1:-}" ;;
  disable)  cmd_disable "${1:-}" ;;
  list)     cmd_list ;;
  status)   cmd_status ;;
  *)        die "Unknown subcommand: ${SUBCOMMAND}. Use: enable|disable|list|status" ;;
esac
