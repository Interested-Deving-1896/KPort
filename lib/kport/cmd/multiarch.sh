#!/usr/bin/env bash
# kport multiarch
#
# Manage multiarch support for non-amd64 architectures.
# Enables/disables Debian sid overlay repositories and registers foreign
# architectures with dpkg.
#
# Usage: kport multiarch <subcommand> [arch]
#
# Subcommands:
#   enable  <arch>   Enable multiarch for arch (i386 | arm64 | riscv64)
#   disable <arch>   Disable multiarch for arch
#   list             List available multiarch overlays and their status
#   status           Show currently enabled foreign architectures
#
# Supported arches: i386  arm64  riscv64
#
# Notes:
#   - enable requires sudo (dpkg --add-architecture, apt-get update)
#   - i386: kwin and plasma-desktop are masked (no 32-bit Vulkan ICD loader)
#   - riscv64: packages come from debian-ports, not the main Debian archive

set -uo pipefail

MULTIARCH_SUPPORTED=(i386 arm64 riscv64)

# Overlay name → arch mapping
_overlay_for_arch() {
  case "$1" in
    i386)    echo "plasma6-i386" ;;
    arm64)   echo "plasma6-arm64" ;;
    riscv64) echo "plasma6-riscv64" ;;
    *)       return 1 ;;
  esac
}

# Debian keyring package needed per arch
_keyring_for_arch() {
  case "$1" in
    riscv64) echo "debian-ports-archive-keyring" ;;
    *)       echo "debian-archive-keyring" ;;
  esac
}

# APT source line for arch
_apt_source_for_arch() {
  case "$1" in
    i386|arm64)
      echo "deb [arch=$1] https://deb.debian.org/debian sid main"
      ;;
    riscv64)
      echo "deb [arch=riscv64] https://deb.debian.org/debian-ports sid main"
      ;;
  esac
}

cmd_enable() {
  local arch="${1:-}"
  if [[ -z "$arch" ]]; then
    kport_die "Usage: kport multiarch enable <arch>  (i386 | arm64 | riscv64)"
  fi

  local overlay
  if ! overlay=$(_overlay_for_arch "$arch"); then
    kport_die "Unsupported arch: ${arch}. Supported: ${MULTIARCH_SUPPORTED[*]}"
  fi

  kport_info "Enabling multiarch for ${arch}..."

  # 1. Register foreign arch with dpkg
  if dpkg --print-foreign-architectures | grep -q "^${arch}$"; then
    kport_info "  dpkg: ${arch} already registered"
  else
    kport_info "  dpkg --add-architecture ${arch}"
    sudo dpkg --add-architecture "${arch}"
  fi

  # 2. Add APT source if not present
  local src_file="/etc/apt/sources.list.d/kport-multiarch-${arch}.list"
  if [[ ! -f "$src_file" ]]; then
    kport_info "  Adding APT source: $(_apt_source_for_arch "$arch")"
    echo "$(_apt_source_for_arch "$arch")" | sudo tee "$src_file" > /dev/null
  else
    kport_info "  APT source already present: ${src_file}"
  fi

  # 3. Install keyring if needed
  local keyring
  keyring=$(_keyring_for_arch "$arch")
  if ! dpkg -l "$keyring" 2>/dev/null | grep -q "^ii"; then
    kport_info "  Installing keyring: ${keyring}"
    sudo apt-get install -y "$keyring"
  fi

  # 4. apt-get update for new arch
  kport_info "  apt-get update (foreign arch packages)..."
  sudo apt-get update -o Dir::Etc::sourcelist="$src_file" \
                      -o Dir::Etc::sourcelistd="" \
                      -o APT::Get::List-Cleanup="0" 2>&1 \
    | grep -E "^(Get|Ign|Err|Hit)" || true

  # 5. Enable the KPort overlay in repositories.yml
  local repos_yml="${KPORT_ROOT}/config/repositories.yml"
  if grep -q "name: ${overlay}" "$repos_yml"; then
    # Flip enabled: false → true for this overlay block
    python3 - "$repos_yml" "$overlay" << 'PYEOF'
import sys, re

path, overlay = sys.argv[1], sys.argv[2]
content = open(path).read()

# Find the overlay block and flip its enabled: field
pattern = rf'(- name: {re.escape(overlay)}\b.*?enabled:)\s*false'
replacement = r'\1 true'
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

if new_content == content:
    print(f"  WARNING: could not find 'enabled: false' for overlay '{overlay}'")
else:
    open(path, 'w').write(new_content)
    print(f"  Overlay '{overlay}' enabled in repositories.yml")
PYEOF
  else
    kport_warn "Overlay '${overlay}' not found in repositories.yml"
  fi

  kport_ok "Multiarch ${arch} enabled. Run 'kport sync --overlay ${overlay}' to sync packages."

  if [[ "$arch" == "i386" ]]; then
    kport_warn "Note: kwin and plasma-desktop are masked on i386 (no 32-bit Vulkan ICD loader)."
    kport_warn "      OpenGL 3.3 is the ceiling. Use Dolphin/Konsole/KF6 apps without a compositor."
  fi
}

cmd_disable() {
  local arch="${1:-}"
  if [[ -z "$arch" ]]; then
    kport_die "Usage: kport multiarch disable <arch>"
  fi

  local overlay
  if ! overlay=$(_overlay_for_arch "$arch"); then
    kport_die "Unsupported arch: ${arch}"
  fi

  kport_info "Disabling multiarch for ${arch}..."

  # Disable overlay in repositories.yml
  local repos_yml="${KPORT_ROOT}/config/repositories.yml"
  python3 - "$repos_yml" "$overlay" << 'PYEOF'
import sys, re
path, overlay = sys.argv[1], sys.argv[2]
content = open(path).read()
pattern = rf'(- name: {re.escape(overlay)}\b.*?enabled:)\s*true'
new_content = re.sub(pattern, r'\1 false', content, flags=re.DOTALL)
if new_content != content:
    open(path, 'w').write(new_content)
    print(f"  Overlay '{overlay}' disabled in repositories.yml")
else:
    print(f"  Overlay '{overlay}' was already disabled")
PYEOF

  # Remove APT source file
  local src_file="/etc/apt/sources.list.d/kport-multiarch-${arch}.list"
  if [[ -f "$src_file" ]]; then
    sudo rm -f "$src_file"
    kport_info "  Removed APT source: ${src_file}"
  fi

  kport_ok "Multiarch ${arch} disabled. Foreign arch packages remain installed until manually removed."
}

cmd_list() {
  local repos_yml="${KPORT_ROOT}/config/repositories.yml"
  kport_info "Available multiarch overlays:"
  printf "  %-22s %-10s %s\n" "OVERLAY" "ARCH" "STATUS"
  printf "  %-22s %-10s %s\n" "-------" "----" "------"
  for arch in "${MULTIARCH_SUPPORTED[@]}"; do
    local overlay
    overlay=$(_overlay_for_arch "$arch")
    local status="disabled"
    if grep -A5 "name: ${overlay}" "$repos_yml" 2>/dev/null | grep -q "enabled: true"; then
      status="enabled"
    fi
    local dpkg_status="not registered"
    if dpkg --print-foreign-architectures 2>/dev/null | grep -q "^${arch}$"; then
      dpkg_status="dpkg registered"
    fi
    printf "  %-22s %-10s %s (%s)\n" "$overlay" "$arch" "$status" "$dpkg_status"
  done
}

cmd_status() {
  kport_info "Foreign architectures registered with dpkg:"
  local arches
  arches=$(dpkg --print-foreign-architectures 2>/dev/null)
  if [[ -z "$arches" ]]; then
    echo "  (none)"
  else
    echo "$arches" | while read -r a; do
      echo "  ${a}"
    done
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
SUBCMD="${KPORT_CMD_ARGS[0]:-list}"
SUBCMD_ARGS=("${KPORT_CMD_ARGS[@]:1}")

case "$SUBCMD" in
  enable)  cmd_enable  "${SUBCMD_ARGS[0]:-}" ;;
  disable) cmd_disable "${SUBCMD_ARGS[0]:-}" ;;
  list)    cmd_list ;;
  status)  cmd_status ;;
  --help|-h)
    sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
    ;;
  *)
    kport_die "Unknown multiarch subcommand: ${SUBCMD}. Try: enable | disable | list | status"
    ;;
esac
