#!/usr/bin/env bash
#
# keyword-tier-check.sh
#
# Unit tests for kport_check_keyword CPU/GPU tier ordering.
# Exercises all arch families including i686, with particular focus on
# cross-family isolation (an i686 package must not block on aarch64).
#
# Usage:
#   bash scripts/kport/keyword-tier-check.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="${KPORT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

# ── Bootstrap minimal kport env ───────────────────────────────────────────────

export KPORT_ROOT
export KPORT_LIB="${KPORT_ROOT}/lib/kport"
export KPORT_DB="${KPORT_ROOT}/.ci-db-kwcheck"
export KPORT_CONF="${KPORT_ROOT}/config"

# Minimal hardware.conf written per test case.
# Must be exported before sourcing common.sh — common.sh respects a
# pre-existing KPORT_HW_CONF value rather than unconditionally overwriting it.
HW_CONF_TMP=$(mktemp)
export KPORT_HW_CONF="$HW_CONF_TMP"

# Minimal pacscript written per test case
PACSCRIPT_TMP=$(mktemp --suffix=.pacscript)

# Minimal keywords.yml — use the real one
export KPORT_CONFIG_DIR="${KPORT_ROOT}/config"

source "${KPORT_LIB}/common.sh"

# ── Test harness ──────────────────────────────────────────────────────────────

PASS=0
FAIL=0

_write_hw() {
  # _write_hw CPU_TIER GPU_TIER
  printf 'CPU_TIER="%s"\nGPU_TIER="%s"\n' "$1" "$2" > "$HW_CONF_TMP"
}

_write_pkg() {
  # _write_pkg KCPU_MIN KGPU_MIN [KNEON_CHANNEL]
  local cpu_min="$1" gpu_min="$2" channel="${3:-stable}"
  cat > "$PACSCRIPT_TMP" << EOF
pkgname="test-pkg"
pkgver="1.0"
KCATEGORY="test"
KNEON_CHANNEL="${channel}"
KCPU_MIN="${cpu_min}"
KGPU_MIN="${gpu_min}"
EOF
}

_write_pkg_no_cpu() {
  # Package with no KCPU_MIN (arch-agnostic)
  local gpu_min="${1:-gpu-sw}" channel="${2:-stable}"
  cat > "$PACSCRIPT_TMP" << EOF
pkgname="test-pkg"
pkgver="1.0"
KCATEGORY="test"
KNEON_CHANNEL="${channel}"
KGPU_MIN="${gpu_min}"
EOF
}

assert_pass() {
  local desc="$1"
  if kport_check_keyword "test-pkg" "test" "$PACSCRIPT_TMP" 2>/dev/null; then
    PASS=$(( PASS + 1 ))
    $VERBOSE && echo "  PASS  $desc"
  else
    FAIL=$(( FAIL + 1 ))
    echo "  FAIL  $desc  (expected: accepted)"
  fi
}

assert_block() {
  local desc="$1"
  if ! kport_check_keyword "test-pkg" "test" "$PACSCRIPT_TMP" 2>/dev/null; then
    PASS=$(( PASS + 1 ))
    $VERBOSE && echo "  PASS  $desc"
  else
    FAIL=$(( FAIL + 1 ))
    echo "  FAIL  $desc  (expected: blocked)"
  fi
}

section() { echo ""; echo "── $* ──"; }

# ── i686 CPU tier tests ───────────────────────────────────────────────────────

section "i686 CPU tiers"

# i686-baseline system meets i686-baseline requirement
_write_hw "i686-baseline" "gpu-sw"
_write_pkg "i686-baseline" "gpu-sw"
assert_pass "i686-baseline system, i686-baseline pkg → accepted"

# i686-sse3 system meets i686-baseline requirement
_write_hw "i686-sse3" "gpu-sw"
_write_pkg "i686-baseline" "gpu-sw"
assert_pass "i686-sse3 system, i686-baseline pkg → accepted"

# i686-sse3 system meets i686-sse3 requirement
_write_hw "i686-sse3" "gpu-sw"
_write_pkg "i686-sse3" "gpu-sw"
assert_pass "i686-sse3 system, i686-sse3 pkg → accepted"

# i686-baseline system does NOT meet i686-sse3 requirement
_write_hw "i686-baseline" "gpu-sw"
_write_pkg "i686-sse3" "gpu-sw"
assert_block "i686-baseline system, i686-sse3 pkg → blocked"

# ── i686 GPU tier tests ───────────────────────────────────────────────────────

section "i686 GPU tiers"

# gpu-sw system meets gpu-sw requirement
_write_hw "i686-baseline" "gpu-sw"
_write_pkg "i686-baseline" "gpu-sw"
assert_pass "i686 gpu-sw system, gpu-sw pkg → accepted"

# gpu-gl2 system meets gpu-sw requirement
_write_hw "i686-baseline" "gpu-gl2"
_write_pkg "i686-baseline" "gpu-sw"
assert_pass "i686 gpu-gl2 system, gpu-sw pkg → accepted"

# gpu-gl4 system meets gpu-gl2 requirement
_write_hw "i686-baseline" "gpu-gl4"
_write_pkg "i686-baseline" "gpu-gl2"
assert_pass "i686 gpu-gl4 system, gpu-gl2 pkg → accepted"

# gpu-sw system does NOT meet gpu-gl2 requirement
_write_hw "i686-baseline" "gpu-sw"
_write_pkg "i686-baseline" "gpu-gl2"
assert_block "i686 gpu-sw system, gpu-gl2 pkg → blocked"

# gpu-gl2 system does NOT meet gpu-gl4 requirement
_write_hw "i686-baseline" "gpu-gl2"
_write_pkg "i686-baseline" "gpu-gl4"
assert_block "i686 gpu-gl2 system, gpu-gl4 pkg → blocked"

# ── Cross-family isolation: i686 pkg on aarch64 system ───────────────────────

section "Cross-family isolation (i686 pkg on aarch64 system)"

# An i686-sse3 KCPU_MIN must NOT block an aarch64 system — different families
_write_hw "aarch64-v8" "gpu-mali-g52"
_write_pkg "i686-sse3" "gpu-sw"
assert_pass "aarch64-v8 system, i686-sse3 pkg → accepted (cross-family, no block)"

# An i686-sse3 KCPU_MIN must NOT block an x86-64 system
_write_hw "x86-64-v1" "gpu-sw"
_write_pkg "i686-sse3" "gpu-sw"
assert_pass "x86-64-v1 system, i686-sse3 pkg → accepted (cross-family, no block)"

# ── Cross-family isolation: x86-64 pkg on i686 system ────────────────────────

section "Cross-family isolation (x86-64 pkg on i686 system)"

# An x86-64-v1 KCPU_MIN must NOT block an i686 system — different families
# (i686 simply can't run x86-64 binaries, but that's enforced by the OS/loader,
# not by kport_check_keyword — keyword check only blocks within the same family)
_write_hw "i686-sse3" "gpu-gl4"
_write_pkg "x86-64-v1" "gpu-sw"
assert_pass "i686-sse3 system, x86-64-v1 pkg → accepted (cross-family, no block)"

# ── Arch-agnostic packages (no KCPU_MIN) ─────────────────────────────────────

section "Arch-agnostic packages (no KCPU_MIN)"

# A package with no KCPU_MIN must be accepted on any arch
_write_hw "i686-baseline" "gpu-sw"
_write_pkg_no_cpu "gpu-sw"
assert_pass "i686-baseline system, no KCPU_MIN pkg → accepted"

_write_hw "aarch64-v8" "gpu-mali-g52"
_write_pkg_no_cpu "gpu-sw"
assert_pass "aarch64-v8 system, no KCPU_MIN pkg → accepted"

_write_hw "riscv64-rv64gc" "gpu-img-bxm"
_write_pkg_no_cpu "gpu-sw"
assert_pass "riscv64-rv64gc system, no KCPU_MIN pkg → accepted"

# ── Existing x86-64 tier ordering (regression) ───────────────────────────────

section "x86-64 CPU tier ordering (regression)"

_write_hw "x86-64-v1" "gpu-sw"
_write_pkg "x86-64-v1" "gpu-sw"
assert_pass "x86-64-v1 system, x86-64-v1 pkg → accepted"

_write_hw "x86-64-v3" "gpu-vk13"
_write_pkg "x86-64-v2" "gpu-gl4"
assert_pass "x86-64-v3 system, x86-64-v2 pkg → accepted"

_write_hw "x86-64-v1" "gpu-sw"
_write_pkg "x86-64-v3" "gpu-sw"
assert_block "x86-64-v1 system, x86-64-v3 pkg → blocked"

# ── Existing aarch64 tier ordering (regression) ──────────────────────────────

section "aarch64 CPU tier ordering (regression)"

_write_hw "aarch64-v8" "gpu-mali-g52"
_write_pkg "aarch64-v8" "gpu-sw"
assert_pass "aarch64-v8 system, aarch64-v8 pkg → accepted"

_write_hw "aarch64-v9" "gpu-adreno-7xx"
_write_pkg "aarch64-v8.2" "gpu-sw"
assert_pass "aarch64-v9 system, aarch64-v8.2 pkg → accepted"

_write_hw "aarch64-v8" "gpu-mali-g52"
_write_pkg "aarch64-v9" "gpu-sw"
assert_block "aarch64-v8 system, aarch64-v9 pkg → blocked"

# ── Adreno GPU tier ordering (regression) ────────────────────────────────────

section "Adreno GPU tier ordering (regression)"

_write_hw "aarch64-v8" "gpu-adreno-6xx"
_write_pkg "aarch64-v8" "gpu-adreno-6xx"
assert_pass "adreno-6xx system, adreno-6xx pkg → accepted"

_write_hw "aarch64-v9" "gpu-adreno-7xx"
_write_pkg "aarch64-v8" "gpu-adreno-6xx"
assert_pass "adreno-7xx system, adreno-6xx pkg → accepted"

_write_hw "aarch64-v8" "gpu-adreno-6xx"
_write_pkg "aarch64-v8" "gpu-adreno-7xx"
assert_block "adreno-6xx system, adreno-7xx pkg → blocked"

# ── Cleanup ───────────────────────────────────────────────────────────────────

rm -f "$HW_CONF_TMP" "$PACSCRIPT_TMP"

# ── Results ───────────────────────────────────────────────────────────────────

echo ""
TOTAL=$(( PASS + FAIL ))
echo "Results: ${PASS}/${TOTAL} passed"

if [[ $FAIL -gt 0 ]]; then
  echo "FAIL: ${FAIL} test(s) failed" >&2
  exit 1
fi

echo "All keyword tier tests passed."
exit 0
