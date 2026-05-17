#!/usr/bin/env bash
#
# KPort CPU compatibility detection.
# Determines the x86-64 microarchitecture level and CPU feature flags.
#
# Outputs shell variable assignments suitable for sourcing or writing
# to hardware.conf:
#   CPU_TIER    — x86-64-v1 | x86-64-v2 | x86-64-v3 | x86-64-v4 | aarch64 | aarch64-v8.2
#   CPU_FLAGS   — space-separated list of detected features
#   CPU_CORES   — logical core count
#   CPU_MODEL   — model name string
#
# Uses x86-64-level (https://github.com/HenrikBengtsson/x86-64-level) when
# available, falls back to /proc/cpuinfo parsing.
#
# Usage:
#   source <(bash scripts/kport/kport-detect-cpu.sh)
#   bash scripts/kport/kport-detect-cpu.sh --export   # prints export statements
#   bash scripts/kport/kport-detect-cpu.sh --json     # prints JSON

set -uo pipefail

EXPORT_MODE=false
JSON_MODE=false
for arg in "$@"; do
  [[ "$arg" == "--export" ]] && EXPORT_MODE=true
  [[ "$arg" == "--json"   ]] && JSON_MODE=true
done

# ── Detect architecture ───────────────────────────────────────────────────────

ARCH=$(uname -m)

detect_aarch64() {
  local tier="aarch64"
  local flags=""

  # Check for ARMv8.2 features
  if grep -q 'asimdrdm\|asimdhp\|dcpop\|sve' /proc/cpuinfo 2>/dev/null; then
    tier="aarch64-v8.2"
    flags="$(grep -o 'asimdrdm\|asimdhp\|dcpop\|sve\|dotprod\|fp16fml' \
      /proc/cpuinfo 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ $//')"
  fi

  local cores model
  cores=$(nproc 2>/dev/null || echo "1")
  model=$(grep -m1 'Model name\|Hardware\|Processor' /proc/cpuinfo 2>/dev/null \
    | sed 's/.*: //' | tr -s ' ' | head -c 80 || echo "Unknown ARM")

  echo "CPU_TIER=\"${tier}\""
  echo "CPU_FLAGS=\"${flags}\""
  echo "CPU_CORES=\"${cores}\""
  echo "CPU_MODEL=\"${model}\""
}

detect_x86_64() {
  local tier="x86-64-v1"
  local flags=""

  # Try x86-64-level tool first (most accurate)
  local x86_level_bin
  x86_level_bin=$(command -v x86-64-level 2>/dev/null \
    || find /usr/local/bin /usr/bin /opt -name 'x86-64-level' 2>/dev/null | head -1)

  if [[ -n "$x86_level_bin" ]]; then
    local level
    level=$("$x86_level_bin" 2>/dev/null) || level="1"
    tier="x86-64-v${level}"
  else
    # Fallback: parse /proc/cpuinfo flags
    local cpuflags
    cpuflags=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | sed 's/flags\s*:\s*//')

    has_flag() { echo "$cpuflags" | grep -qw "$1"; }

    # v2: SSE3, SSSE3, SSE4.1, SSE4.2, POPCNT, CX16, LAHF
    if has_flag sse3 && has_flag ssse3 && has_flag sse4_1 && \
       has_flag sse4_2 && has_flag popcnt && has_flag cx16; then
      tier="x86-64-v2"

      # v3: AVX, AVX2, BMI1, BMI2, FMA, MOVBE, XSAVE
      if has_flag avx && has_flag avx2 && has_flag bmi1 && \
         has_flag bmi2 && has_flag fma && has_flag movbe; then
        tier="x86-64-v3"

        # v4: AVX-512 (F, BW, CD, DQ, VL)
        if has_flag avx512f && has_flag avx512bw && has_flag avx512cd && \
           has_flag avx512dq && has_flag avx512vl; then
          tier="x86-64-v4"
        fi
      fi
    fi
  fi

  # Collect notable feature flags
  local cpuflags
  cpuflags=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | sed 's/flags\s*:\s*//')
  local notable=()
  for f in avx avx2 avx512f fma bmi1 bmi2 aes sha_ni vaes vpclmulqdq \
            sse4_1 sse4_2 popcnt cx16 movbe xsave; do
    echo "$cpuflags" | grep -qw "$f" && notable+=("$f")
  done
  flags="${notable[*]:-}"

  local cores model
  cores=$(nproc 2>/dev/null || echo "1")
  model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null \
    | sed 's/model name\s*:\s*//' | tr -s ' ' | head -c 80 || echo "Unknown x86")

  echo "CPU_TIER=\"${tier}\""
  echo "CPU_FLAGS=\"${flags}\""
  echo "CPU_CORES=\"${cores}\""
  echo "CPU_MODEL=\"${model}\""
}

# ── Run detection ─────────────────────────────────────────────────────────────

raw_output=""
case "$ARCH" in
  aarch64|arm64) raw_output=$(detect_aarch64) ;;
  x86_64)        raw_output=$(detect_x86_64)  ;;
  *)
    raw_output="CPU_TIER=\"unknown\""$'\n'
    raw_output+="CPU_FLAGS=\"\""$'\n'
    raw_output+="CPU_CORES=\"$(nproc 2>/dev/null || echo 1)\""$'\n'
    raw_output+="CPU_MODEL=\"${ARCH}\""
    ;;
esac

# ── Output ────────────────────────────────────────────────────────────────────

if [[ "$JSON_MODE" == "true" ]]; then
  eval "$raw_output"
  printf '{"cpu_tier":"%s","cpu_flags":"%s","cpu_cores":%s,"cpu_model":"%s"}\n' \
    "${CPU_TIER}" "${CPU_FLAGS}" "${CPU_CORES}" "${CPU_MODEL//\"/\\\"}"
elif [[ "$EXPORT_MODE" == "true" ]]; then
  echo "$raw_output" | sed 's/^/export /'
else
  echo "$raw_output"
fi
