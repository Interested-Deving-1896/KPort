#!/usr/bin/env bash
#
# KPort NPU/AI accelerator compatibility detection.
# Determines NPU tier and capability flags for on-device AI inference.
#
# Outputs shell variable assignments:
#   NPU_TIER    — npu-none | npu-igpu | npu-dedicated | npu-ai | npu-datacenter
#   NPU_FLAGS   — space-separated: opencl intel-npu amd-xdna qualcomm-htp cuda-tensor
#   NPU_MODEL   — NPU/accelerator model name
#   NPU_TOPS    — estimated TOPS (0 if unknown)
#
# Detection sources (in order):
#   1. /dev/accel/*          — Linux accelerator device nodes (kernel 6.2+)
#   2. intel_npu_top         — Intel NPU (Meteor Lake, Lunar Lake, Arrow Lake)
#   3. /sys/bus/platform     — ARM NPU kernel drivers
#   4. rocm-smi / amdxdna   — AMD XDNA (Ryzen AI, Strix Point)
#   5. nvidia-smi            — NVIDIA Tensor Cores
#   6. clinfo                — OpenCL compute (iGPU fallback)
#   7. /proc/cpuinfo         — CPU-integrated NPU hints
#
# Usage:
#   source <(bash scripts/kport/kport-detect-npu.sh)
#   bash scripts/kport/kport-detect-npu.sh --export
#   bash scripts/kport/kport-detect-npu.sh --json

set -uo pipefail

EXPORT_MODE=false
JSON_MODE=false
for arg in "$@"; do
  [[ "$arg" == "--export" ]] && EXPORT_MODE=true
  [[ "$arg" == "--json"   ]] && JSON_MODE=true
done

NPU_TIER="npu-none"
NPU_FLAGS=""
NPU_MODEL="None"
NPU_TOPS="0"

declare -a npu_flags=()

# ── Intel NPU detection ───────────────────────────────────────────────────────
# Intel NPU present on Meteor Lake (Core Ultra 1xx), Lunar Lake (Core Ultra 2xx),
# Arrow Lake. Exposed via /dev/accel/accel0 and the intel_vpu kernel driver.

detect_intel_npu() {
  # Check for Intel VPU/NPU kernel driver
  if lsmod 2>/dev/null | grep -q 'intel_vpu\|intel_npu'; then
    NPU_TIER="npu-dedicated"
    npu_flags+=("intel-npu")

    # Identify generation from CPU model
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null \
      | sed 's/.*: //' | tr '[:upper:]' '[:lower:]')

    if echo "$cpu_model" | grep -qE 'ultra [12][0-9]{2}|meteor lake|lunar lake|arrow lake'; then
      NPU_TIER="npu-ai"
      # Meteor Lake: ~10 TOPS, Lunar Lake: ~48 TOPS, Arrow Lake: ~13 TOPS
      if echo "$cpu_model" | grep -qi 'lunar lake\|ultra 2'; then
        NPU_TOPS="48"
        NPU_MODEL="Intel NPU (Lunar Lake)"
      elif echo "$cpu_model" | grep -qi 'arrow lake'; then
        NPU_TOPS="13"
        NPU_MODEL="Intel NPU (Arrow Lake)"
      else
        NPU_TOPS="10"
        NPU_MODEL="Intel NPU (Meteor Lake)"
      fi
    else
      NPU_MODEL="Intel VPU/NPU"
      NPU_TOPS="10"
    fi
    return 0
  fi

  # Check /dev/accel/ device nodes (kernel 6.2+ accelerator subsystem)
  if ls /dev/accel/accel* &>/dev/null 2>&1; then
    for accel in /dev/accel/accel*; do
      local driver
      driver=$(readlink -f "/sys/class/accel/$(basename "$accel")/device/driver" \
        2>/dev/null | xargs basename 2>/dev/null || echo "")
      if [[ "$driver" == *"intel"* || "$driver" == *"vpu"* || "$driver" == *"npu"* ]]; then
        NPU_TIER="npu-dedicated"
        NPU_MODEL="Intel Accelerator (${driver})"
        NPU_TOPS="10"
        npu_flags+=("intel-npu")
        return 0
      fi
    done
  fi

  return 1
}

# ── AMD XDNA detection ────────────────────────────────────────────────────────
# AMD XDNA NPU present on Ryzen AI (Phoenix, Hawk Point), Strix Point (Ryzen AI 300).

detect_amd_xdna() {
  if lsmod 2>/dev/null | grep -q 'amdxdna\|amd_ipu'; then
    NPU_TIER="npu-ai"
    npu_flags+=("amd-xdna")

    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null \
      | sed 's/.*: //' | tr '[:upper:]' '[:lower:]')

    if echo "$cpu_model" | grep -qiE 'ryzen ai 3[0-9]{2}|strix'; then
      NPU_TOPS="50"
      NPU_MODEL="AMD XDNA2 (Strix Point)"
    elif echo "$cpu_model" | grep -qiE 'ryzen ai|phoenix|hawk point'; then
      NPU_TOPS="16"
      NPU_MODEL="AMD XDNA (Ryzen AI)"
    else
      NPU_TOPS="16"
      NPU_MODEL="AMD XDNA NPU"
    fi
    return 0
  fi

  # Check via amdxdna sysfs
  if [[ -d /sys/bus/platform/drivers/amdxdna ]]; then
    NPU_TIER="npu-ai"
    NPU_MODEL="AMD XDNA NPU"
    NPU_TOPS="16"
    npu_flags+=("amd-xdna")
    return 0
  fi

  return 1
}

# ── NVIDIA Tensor Core detection ──────────────────────────────────────────────

detect_nvidia_tensor() {
  command -v nvidia-smi &>/dev/null || return 1
  nvidia-smi &>/dev/null || return 1

  local gpu_name compute_cap
  gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
  compute_cap=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1)

  [[ -z "$gpu_name" ]] && return 1

  npu_flags+=("cuda-tensor")

  # Determine tier from compute capability
  # 7.0+ = Volta (Tensor Cores gen1), 8.0+ = Ampere (gen3), 9.0+ = Hopper
  local major
  major=$(echo "$compute_cap" | cut -d. -f1)

  if [[ "$major" -ge 9 ]]; then
    NPU_TIER="npu-datacenter"
    NPU_TOPS="3958"   # H100 SXM
    NPU_MODEL="NVIDIA ${gpu_name} (Hopper)"
  elif [[ "$major" -ge 8 ]]; then
    # Ampere: RTX 30xx consumer vs A100 datacenter
    if echo "$gpu_name" | grep -qiE 'A100|A30|A40|A6000'; then
      NPU_TIER="npu-datacenter"
      NPU_TOPS="312"
    else
      NPU_TIER="npu-ai"
      NPU_TOPS="82"   # RTX 3090 approximate
    fi
    NPU_MODEL="NVIDIA ${gpu_name} (Ampere)"
  elif [[ "$major" -ge 7 ]]; then
    NPU_TIER="npu-dedicated"
    NPU_TOPS="14"   # RTX 2080 approximate
    NPU_MODEL="NVIDIA ${gpu_name} (Turing/Volta)"
  else
    NPU_TIER="npu-igpu"
    NPU_TOPS="0"
    NPU_MODEL="NVIDIA ${gpu_name}"
  fi

  return 0
}

# ── Qualcomm HTP detection ────────────────────────────────────────────────────

detect_qualcomm_htp() {
  if ls /dev/qaic* &>/dev/null 2>&1 || \
     [[ -d /sys/bus/platform/drivers/qcom-npu ]] || \
     lsmod 2>/dev/null | grep -q 'qcom_npu\|qaic'; then
    NPU_TIER="npu-ai"
    NPU_MODEL="Qualcomm HTP/NPU"
    NPU_TOPS="15"
    npu_flags+=("qualcomm-htp")
    return 0
  fi
  return 1
}

# ── ARM NPU detection ─────────────────────────────────────────────────────────

detect_arm_npu() {
  # Ethos-N NPU (Arm ML IP)
  if lsmod 2>/dev/null | grep -q 'ethosn\|arm_npu'; then
    NPU_TIER="npu-dedicated"
    NPU_MODEL="Arm Ethos-N NPU"
    NPU_TOPS="4"
    npu_flags+=("arm-npu")
    return 0
  fi
  return 1
}

# ── OpenCL iGPU fallback ──────────────────────────────────────────────────────
# If no dedicated NPU found but OpenCL is available via iGPU, classify as npu-igpu

detect_opencl_igpu() {
  command -v clinfo &>/dev/null || return 1

  local platform_count
  platform_count=$(clinfo 2>/dev/null | grep 'Number of platforms' \
    | grep -oP '\d+' | head -1)

  [[ "${platform_count:-0}" -gt 0 ]] || return 1

  NPU_TIER="npu-igpu"
  NPU_MODEL="OpenCL iGPU compute"
  NPU_TOPS="0"
  npu_flags+=("opencl")
  return 0
}

# ── Run detection ─────────────────────────────────────────────────────────────

detect_intel_npu    || \
detect_amd_xdna     || \
detect_nvidia_tensor || \
detect_qualcomm_htp || \
detect_arm_npu      || \
detect_opencl_igpu  || \
true   # npu-none is the safe default

NPU_FLAGS="${npu_flags[*]:-}"

# ── Output ────────────────────────────────────────────────────────────────────

raw_output="NPU_TIER=\"${NPU_TIER}\""$'\n'
raw_output+="NPU_FLAGS=\"${NPU_FLAGS}\""$'\n'
raw_output+="NPU_MODEL=\"${NPU_MODEL}\""$'\n'
raw_output+="NPU_TOPS=\"${NPU_TOPS}\""

if [[ "$JSON_MODE" == "true" ]]; then
  printf '{"npu_tier":"%s","npu_flags":"%s","npu_model":"%s","npu_tops":%s}\n' \
    "$NPU_TIER" "$NPU_FLAGS" "${NPU_MODEL//\"/\\\"}" "$NPU_TOPS"
elif [[ "$EXPORT_MODE" == "true" ]]; then
  echo "$raw_output" | sed 's/^/export /'
else
  echo "$raw_output"
fi
