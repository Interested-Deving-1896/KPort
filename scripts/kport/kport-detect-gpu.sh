#!/usr/bin/env bash
#
# KPort GPU compatibility detection.
# Determines GPU tier, vendor, and capability flags.
#
# Outputs shell variable assignments:
#   GPU_TIER      — gpu-sw | gpu-gl2 | gpu-gl4 | gpu-vk12 | gpu-vk13
#   GPU_VENDOR    — gpu-intel | gpu-amd | gpu-nvidia | gpu-nvidia-proprietary | gpu-unknown
#   GPU_FLAGS     — space-separated: vulkan vaapi vdpau rocm opencl
#   GPU_MODEL     — GPU model name string
#   GPU_VRAM_MB   — VRAM in MB (0 if unknown)
#
# Detection order:
#   1. vulkaninfo  — most accurate for tier and Vulkan version
#   2. glxinfo     — OpenGL version fallback
#   3. /sys/class/drm — kernel DRM device enumeration
#   4. lspci       — PCI device fallback
#
# Usage:
#   source <(bash scripts/kport/kport-detect-gpu.sh)
#   bash scripts/kport/kport-detect-gpu.sh --export
#   bash scripts/kport/kport-detect-gpu.sh --json

set -uo pipefail

EXPORT_MODE=false
JSON_MODE=false
for arg in "$@"; do
  [[ "$arg" == "--export" ]] && EXPORT_MODE=true
  [[ "$arg" == "--json"   ]] && JSON_MODE=true
done

GPU_TIER="gpu-sw"
GPU_VENDOR="gpu-unknown"
GPU_FLAGS=""
GPU_MODEL="Unknown"
GPU_VRAM_MB="0"

# ── Vendor detection from DRM / lspci ────────────────────────────────────────

detect_vendor_from_drm() {
  # /sys/class/drm/card*/device/vendor contains PCI vendor ID
  for card in /sys/class/drm/card*/device/vendor; do
    [[ -f "$card" ]] || continue
    local vendor_id
    vendor_id=$(cat "$card" 2>/dev/null)
    case "$vendor_id" in
      0x8086) echo "gpu-intel";  return ;;
      0x1002) echo "gpu-amd";    return ;;
      0x10de) echo "gpu-nvidia"; return ;;
    esac
  done
  echo "gpu-unknown"
}

detect_vendor_from_lspci() {
  if command -v lspci &>/dev/null; then
    local pci_out
    pci_out=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display')
    if echo "$pci_out" | grep -qi 'intel';  then echo "gpu-intel";  return; fi
    if echo "$pci_out" | grep -qi 'amd\|radeon\|advanced micro'; then echo "gpu-amd"; return; fi
    if echo "$pci_out" | grep -qi 'nvidia'; then echo "gpu-nvidia"; return; fi
  fi
  echo "gpu-unknown"
}

detect_model_from_drm() {
  for card in /sys/class/drm/card*/device; do
    local label
    label=$(cat "$card/label" 2>/dev/null \
      || cat "$card/product_name" 2>/dev/null \
      || cat "$card/../product_name" 2>/dev/null) || true
    [[ -n "$label" ]] && echo "$label" && return
  done

  if command -v lspci &>/dev/null; then
    lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 \
      | sed 's/.*: //' | head -c 80
    return
  fi
  echo "Unknown GPU"
}

# ── Vulkan detection (most accurate) ─────────────────────────────────────────

detect_via_vulkan() {
  command -v vulkaninfo &>/dev/null || return 1

  local vk_out
  vk_out=$(vulkaninfo --summary 2>/dev/null) || return 1

  # Extract Vulkan API version
  local vk_version
  vk_version=$(echo "$vk_out" | grep -i 'apiVersion\|Vulkan Instance Version' \
    | grep -oP '\d+\.\d+' | head -1)

  local major minor
  major=$(echo "$vk_version" | cut -d. -f1)
  minor=$(echo "$vk_version" | cut -d. -f2)

  if [[ "$major" -ge 1 && "$minor" -ge 3 ]]; then
    GPU_TIER="gpu-vk13"
  elif [[ "$major" -ge 1 && "$minor" -ge 2 ]]; then
    GPU_TIER="gpu-vk12"
  elif [[ "$major" -ge 1 ]]; then
    GPU_TIER="gpu-gl4"   # Vulkan 1.0/1.1 — treat as gl4 tier
  fi

  # Extract GPU name from vulkaninfo
  local gpu_name
  gpu_name=$(echo "$vk_out" | grep -i 'deviceName\|GPU id' \
    | head -1 | sed 's/.*= //' | sed 's/.*: //' | tr -s ' ' | head -c 80)
  [[ -n "$gpu_name" ]] && GPU_MODEL="$gpu_name"

  # VRAM from vulkaninfo
  local vram
  vram=$(echo "$vk_out" | grep -i 'heapSize\|VRAM' \
    | grep -oP '\d+' | sort -rn | head -1)
  if [[ -n "$vram" && "$vram" -gt 1000000 ]]; then
    GPU_VRAM_MB=$(( vram / 1024 / 1024 ))
  fi

  return 0
}

# ── OpenGL detection (fallback) ───────────────────────────────────────────────

detect_via_opengl() {
  command -v glxinfo &>/dev/null || return 1

  local gl_out
  gl_out=$(glxinfo 2>/dev/null) || return 1

  local gl_version
  gl_version=$(echo "$gl_out" | grep 'OpenGL version string' \
    | grep -oP '\d+\.\d+' | head -1)

  local major minor
  major=$(echo "$gl_version" | cut -d. -f1)
  minor=$(echo "$gl_version" | cut -d. -f2)

  if [[ "$major" -ge 4 ]]; then
    GPU_TIER="gpu-gl4"
  elif [[ "$major" -ge 2 ]]; then
    GPU_TIER="gpu-gl2"
  fi

  local gpu_name
  gpu_name=$(echo "$gl_out" | grep 'OpenGL renderer string' \
    | sed 's/.*: //' | head -c 80)
  [[ -n "$gpu_name" ]] && GPU_MODEL="$gpu_name"

  return 0
}

# ── Capability flag detection ─────────────────────────────────────────────────

detect_capability_flags() {
  local flags=()

  # Vulkan
  [[ "$GPU_TIER" == gpu-vk* ]] && flags+=("vulkan")

  # VA-API (Intel/AMD hardware video decode)
  if command -v vainfo &>/dev/null; then
    vainfo &>/dev/null && flags+=("vaapi")
  elif [[ -e /dev/dri/renderD128 ]] && \
       [[ "$GPU_VENDOR" == "gpu-intel" || "$GPU_VENDOR" == "gpu-amd" ]]; then
    flags+=("vaapi")
  fi

  # VDPAU (NVIDIA legacy)
  if command -v vdpauinfo &>/dev/null; then
    vdpauinfo &>/dev/null && flags+=("vdpau")
  fi

  # ROCm (AMD compute)
  if command -v rocm-smi &>/dev/null || [[ -d /opt/rocm ]]; then
    flags+=("rocm")
    # ROCm implies proprietary-equivalent capability
    [[ "$GPU_VENDOR" == "gpu-amd" ]] && GPU_VENDOR="gpu-amd"
  fi

  # NVIDIA proprietary
  if command -v nvidia-smi &>/dev/null; then
    nvidia-smi &>/dev/null && {
      GPU_VENDOR="gpu-nvidia-proprietary"
      flags+=("cuda")
    }
  fi

  # OpenCL
  if command -v clinfo &>/dev/null; then
    clinfo 2>/dev/null | grep -q 'Number of platforms.*[1-9]' && flags+=("opencl")
  fi

  GPU_FLAGS="${flags[*]:-}"
}

# ── Run detection ─────────────────────────────────────────────────────────────

GPU_VENDOR=$(detect_vendor_from_drm)
[[ "$GPU_VENDOR" == "gpu-unknown" ]] && GPU_VENDOR=$(detect_vendor_from_lspci)
GPU_MODEL=$(detect_model_from_drm)

# Try Vulkan first, fall back to OpenGL
detect_via_vulkan || detect_via_opengl || true

detect_capability_flags

# ── Output ────────────────────────────────────────────────────────────────────

raw_output="GPU_TIER=\"${GPU_TIER}\""$'\n'
raw_output+="GPU_VENDOR=\"${GPU_VENDOR}\""$'\n'
raw_output+="GPU_FLAGS=\"${GPU_FLAGS}\""$'\n'
raw_output+="GPU_MODEL=\"${GPU_MODEL}\""$'\n'
raw_output+="GPU_VRAM_MB=\"${GPU_VRAM_MB}\""

if [[ "$JSON_MODE" == "true" ]]; then
  printf '{"gpu_tier":"%s","gpu_vendor":"%s","gpu_flags":"%s","gpu_model":"%s","gpu_vram_mb":%s}\n' \
    "$GPU_TIER" "$GPU_VENDOR" "$GPU_FLAGS" "${GPU_MODEL//\"/\\\"}" "$GPU_VRAM_MB"
elif [[ "$EXPORT_MODE" == "true" ]]; then
  echo "$raw_output" | sed 's/^/export /'
else
  echo "$raw_output"
fi
