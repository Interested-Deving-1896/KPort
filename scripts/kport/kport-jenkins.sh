#!/usr/bin/env bash
# kport-jenkins.sh — KDE Neon Jenkins / build.neon.kde.org integration
#
# Queries the KDE Neon Jenkins instance at build.neon.kde.org for build
# status, last successful build metadata, and binary package availability.
#
# In KPort terms this is the binary package host (analogous to Portage's
# PORTAGE_BINHOST). It tells KPort:
#   - Whether a package's upstream build is currently green
#   - What version was last successfully built
#   - Whether a pre-built .deb is available to pull instead of building
#
# Usage:
#   kport-jenkins.sh status  <package>              # build status for a package
#   kport-jenkins.sh version <package>              # last successful build version
#   kport-jenkins.sh check-all [--channel CHANNEL]  # check all KPort packages
#   kport-jenkins.sh gate    <package>              # exit 0 if green, 1 if not
#   kport-jenkins.sh sync    [--channel CHANNEL]    # write build-status cache
#
# Environment:
#   KPORT_JENKINS_URL     Jenkins base URL (default: https://build.neon.kde.org)
#   KPORT_JENKINS_CACHE   Cache file path (default: ~/.cache/kport/jenkins-status.json)
#   KPORT_NEON_CHANNEL    Default channel: stable | unstable | nightly (default: stable)
#
# The cache is used by kport install/upgrade to gate binary pulls on green
# upstream builds — analogous to Portage's FEATURES=binpkg-request-signature.

set -euo pipefail

KPORT_JENKINS_URL="${KPORT_JENKINS_URL:-https://build.neon.kde.org}"
KPORT_JENKINS_CACHE="${KPORT_JENKINS_CACHE:-${HOME}/.cache/kport/jenkins-status.json}"
KPORT_NEON_CHANNEL="${KPORT_NEON_CHANNEL:-stable}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { echo "[kport-jenkins] $*"; }
warn()  { echo "[kport-jenkins] WARN: $*" >&2; }
die()   { echo "[kport-jenkins] ERROR: $*" >&2; exit 1; }

require_cmd() { command -v "$1" &>/dev/null || die "'$1' not found — install $2"; }

# Map KPort channel names to Jenkins job path prefixes
# Jenkins job structure: /job/neon/job/<channel>/job/<component>/job/<package>
_channel_path() {
  case "${1:-$KPORT_NEON_CHANNEL}" in
    stable)   echo "release" ;;
    unstable) echo "unstable" ;;
    nightly)  echo "nightly" ;;
    *)        die "Unknown channel: $1 (use stable|unstable|nightly)" ;;
  esac
}

# Map a KPort package name to its Jenkins job component path
# Jenkins organises by component: frameworks, plasma, applications, gear
_package_component() {
  local pkg="$1"
  local pkg_dir="${KPORT_ROOT}/packages"

  if [[ -f "${pkg_dir}/frameworks/${pkg}/PKGBUILD" ]] || \
     ls "${pkg_dir}/frameworks/${pkg}/"*.pacscript &>/dev/null 2>&1; then
    echo "frameworks"
  elif [[ -d "${pkg_dir}/plasma/${pkg}" ]]; then
    echo "plasma"
  elif [[ -d "${pkg_dir}/gear/${pkg}" ]]; then
    echo "gear"
  else
    echo "applications"
  fi
}

# Fetch JSON from Jenkins API with retry on transient failures
_jenkins_api() {
  local path="$1"
  local url="${KPORT_JENKINS_URL}${path}"
  local attempt=0

  while (( attempt < 3 )); do
    local out http_code body
    out=$(curl -s -w "\n%{http_code}" \
      -H "Accept: application/json" \
      --connect-timeout 10 \
      "$url" 2>/dev/null)
    http_code=$(tail -1 <<< "$out")
    body=$(head -n -1 <<< "$out")

    case "$http_code" in
      200) echo "$body"; return 0 ;;
      404) echo "{}"; return 1 ;;
      429|503) sleep $(( (attempt + 1) * 5 )); (( attempt++ )) ;;
      *)   warn "Jenkins API returned $http_code for $path"; echo "{}"; return 1 ;;
    esac
  done
  warn "Jenkins API unreachable after 3 attempts: $path"
  echo "{}"
  return 1
}

# ── status ────────────────────────────────────────────────────────────────────

cmd_status() {
  local pkg="${1:-}" channel="${KPORT_NEON_CHANNEL}"
  [[ -n "$pkg" ]] || die "Usage: kport-jenkins status <package> [--channel CHANNEL]"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) channel="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  local ch_path component
  ch_path=$(_channel_path "$channel")
  component=$(_package_component "$pkg")

  local api_path="/job/neon/job/${ch_path}/job/${component}/job/${pkg}/lastBuild/api/json"
  local result
  result=$(_jenkins_api "$api_path" 2>/dev/null) || {
    echo "UNKNOWN (package not found on Jenkins)"
    return 0
  }

  local result_str number timestamp
  result_str=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('result','IN_PROGRESS') or 'IN_PROGRESS')" 2>/dev/null || echo "UNKNOWN")
  number=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('number','?'))" 2>/dev/null || echo "?")
  timestamp=$(echo "$result" | python3 -c "
import json,sys,datetime
d=json.load(sys.stdin)
ts=d.get('timestamp',0)
if ts: print(datetime.datetime.utcfromtimestamp(ts/1000).strftime('%Y-%m-%d %H:%M UTC'))
else: print('unknown')
" 2>/dev/null || echo "unknown")

  echo "${pkg} [${channel}/${component}]"
  echo "  Build #${number}: ${result_str} (${timestamp})"
  echo "  URL: ${KPORT_JENKINS_URL}/job/neon/job/${ch_path}/job/${component}/job/${pkg}/"
}

# ── version ───────────────────────────────────────────────────────────────────

cmd_version() {
  local pkg="${1:-}" channel="${KPORT_NEON_CHANNEL}"
  [[ -n "$pkg" ]] || die "Usage: kport-jenkins version <package> [--channel CHANNEL]"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) channel="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  local ch_path component
  ch_path=$(_channel_path "$channel")
  component=$(_package_component "$pkg")

  local api_path="/job/neon/job/${ch_path}/job/${component}/job/${pkg}/lastSuccessfulBuild/api/json"
  local result
  result=$(_jenkins_api "$api_path" 2>/dev/null) || {
    echo "unknown"
    return 0
  }

  # Extract version from build description or artifact names
  python3 - "$pkg" <<'EOF'
import json, sys, re

pkg = sys.argv[1]
try:
    d = json.loads(sys.stdin.read())
except Exception:
    print("unknown")
    sys.exit(0)

# Try build description first (Pangea sets this to the package version)
desc = d.get("description") or ""
m = re.search(r'(\d+[\.\d]+-\d+)', desc)
if m:
    print(m.group(1))
    sys.exit(0)

# Try artifact names: e.g. plasma-desktop_5.27.11-0neon+22.04+jammy+release+build123_amd64.deb
for art in d.get("artifacts", []):
    name = art.get("fileName", "")
    m = re.search(r'_(\d+[\.\d]+-\d+(?:neon[^_]*)?)_', name)
    if m:
        print(m.group(1))
        sys.exit(0)

# Fall back to build number
print(f"build-{d.get('number', 'unknown')}")
EOF
}

# ── gate ──────────────────────────────────────────────────────────────────────

cmd_gate() {
  local pkg="${1:-}" channel="${KPORT_NEON_CHANNEL}"
  [[ -n "$pkg" ]] || die "Usage: kport-jenkins gate <package> [--channel CHANNEL]"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) channel="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  local ch_path component
  ch_path=$(_channel_path "$channel")
  component=$(_package_component "$pkg")

  local api_path="/job/neon/job/${ch_path}/job/${component}/job/${pkg}/lastBuild/api/json"
  local result result_str
  result=$(_jenkins_api "$api_path" 2>/dev/null) || { warn "$pkg: not found on Jenkins — allowing"; return 0; }
  result_str=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('result','') or '')" 2>/dev/null || echo "")

  case "$result_str" in
    SUCCESS) return 0 ;;
    "")      warn "$pkg: build in progress — allowing"; return 0 ;;
    *)       warn "$pkg: upstream build is $result_str — blocking"; return 1 ;;
  esac
}

# ── check-all ─────────────────────────────────────────────────────────────────

cmd_check_all() {
  local channel="${KPORT_NEON_CHANNEL}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) channel="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  local pkg_dir="${KPORT_ROOT}/packages"
  local pass=0 fail=0 unknown=0

  info "Checking all KPort packages against Jenkins [channel: $channel]"
  echo ""

  for component in frameworks plasma gear; do
    [[ -d "${pkg_dir}/${component}" ]] || continue
    for pkg_path in "${pkg_dir}/${component}"/*/; do
      local pkg
      pkg=$(basename "$pkg_path")
      local ch_path
      ch_path=$(_channel_path "$channel")
      local api_path="/job/neon/job/${ch_path}/job/${component}/job/${pkg}/lastBuild/api/json"
      local result result_str
      result=$(_jenkins_api "$api_path" 2>/dev/null) || { (( unknown++ )); continue; }
      result_str=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('result','') or 'IN_PROGRESS')" 2>/dev/null || echo "UNKNOWN")

      case "$result_str" in
        SUCCESS)     printf "  ✓ %-40s %s\n" "$pkg" "$result_str"; (( pass++ )) ;;
        IN_PROGRESS) printf "  ~ %-40s %s\n" "$pkg" "$result_str"; (( unknown++ )) ;;
        *)           printf "  ✗ %-40s %s\n" "$pkg" "$result_str"; (( fail++ )) ;;
      esac
      sleep 0.2  # be polite to Jenkins
    done
  done

  echo ""
  echo "Results: ${pass} passing  ${fail} failing  ${unknown} unknown/in-progress"
  [[ "$fail" -eq 0 ]]
}

# ── sync ──────────────────────────────────────────────────────────────────────

cmd_sync() {
  local channel="${KPORT_NEON_CHANNEL}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) channel="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  local pkg_dir="${KPORT_ROOT}/packages"
  local cache_dir
  cache_dir="$(dirname "$KPORT_JENKINS_CACHE")"
  mkdir -p "$cache_dir"

  info "Syncing Jenkins build status cache [channel: $channel]"

  python3 - "$KPORT_JENKINS_CACHE" <<PYEOF
import json, sys
cache_path = sys.argv[1]
try:
    with open(cache_path) as f:
        cache = json.load(f)
except Exception:
    cache = {}
cache["_meta"] = {"channel": "${channel}", "synced_at": __import__('datetime').datetime.utcnow().isoformat()}
with open(cache_path, "w") as f:
    json.dump(cache, f, indent=2)
PYEOF

  local ch_path
  ch_path=$(_channel_path "$channel")

  for component in frameworks plasma gear; do
    [[ -d "${pkg_dir}/${component}" ]] || continue
    for pkg_path in "${pkg_dir}/${component}"/*/; do
      local pkg
      pkg=$(basename "$pkg_path")
      local api_path="/job/neon/job/${ch_path}/job/${component}/job/${pkg}/lastBuild/api/json"
      local result result_str number
      result=$(_jenkins_api "$api_path" 2>/dev/null) || continue
      result_str=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('result','') or 'IN_PROGRESS')" 2>/dev/null || echo "UNKNOWN")
      number=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('number','?'))" 2>/dev/null || echo "?")

      python3 - "$KPORT_JENKINS_CACHE" "$pkg" "$component" "$result_str" "$number" <<'PYEOF'
import json, sys
cache_path, pkg, component, status, number = sys.argv[1:]
try:
    with open(cache_path) as f: cache = json.load(f)
except Exception: cache = {}
cache[pkg] = {"component": component, "status": status, "build": number}
with open(cache_path, "w") as f: json.dump(cache, f, indent=2)
PYEOF
      sleep 0.2
    done
  done

  info "Cache written to: $KPORT_JENKINS_CACHE"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  status)    cmd_status    "$@" ;;
  version)   cmd_version   "$@" ;;
  gate)      cmd_gate      "$@" ;;
  check-all) cmd_check_all "$@" ;;
  sync)      cmd_sync      "$@" ;;
  ""|help)
    echo "Usage: kport-jenkins <subcommand> [options]"
    echo ""
    echo "Subcommands:"
    echo "  status    <pkg>   Show last build status for a package"
    echo "  version   <pkg>   Show last successfully built version"
    echo "  gate      <pkg>   Exit 0 if upstream build is green, 1 otherwise"
    echo "  check-all         Check all KPort packages against Jenkins"
    echo "  sync              Write build-status cache to disk"
    echo ""
    echo "Options:"
    echo "  --channel CHANNEL  stable | unstable | nightly (default: stable)"
    echo ""
    echo "Environment:"
    echo "  KPORT_JENKINS_URL    Jenkins base URL (default: https://build.neon.kde.org)"
    echo "  KPORT_JENKINS_CACHE  Cache file (default: ~/.cache/kport/jenkins-status.json)"
    echo "  KPORT_NEON_CHANNEL   Default channel (default: stable)"
    ;;
  *) die "Unknown subcommand: $SUBCOMMAND (run kport-jenkins help)" ;;
esac
