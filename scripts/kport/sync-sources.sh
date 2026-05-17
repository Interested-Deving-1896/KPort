#!/usr/bin/env bash
#
# sync-sources.sh
#
# Fetches the project list for each enabled GitLab source in config/sources.yml
# and writes a cache to db/sources-cache.json.
#
# generate-pacscripts.sh reads this cache when present, avoiding repeated
# GitLab group enumeration on every generator run.
#
# Usage:
#   sync-sources.sh [options]
#
# Options:
#   --source <name>   Refresh only the named source (substring match on name)
#   --force           Re-fetch even if cache is less than MAX_CACHE_AGE_HOURS old
#   --dry-run         Print what would be fetched without writing the cache
#   --help
#
# Required env vars:
#   KPORT_ROOT        Path to KPort repo root (default: repo root relative to script)
#   GITLAB_TOKEN      GitLab PAT for invent.kde.org (optional — raises rate limits)
#
# Cache format (db/sources-cache.json):
#   {
#     "generated_at": "<ISO8601>",
#     "sources": {
#       "<group_path>": {
#         "group_id": <int>,
#         "fetched_at": "<ISO8601>",
#         "projects": [
#           { "id": <int>, "path": "<str>", "path_with_namespace": "<str>",
#             "default_branch": "<str>", "description": "<str>" },
#           ...
#         ]
#       }
#     }
#   }

set -uo pipefail

# ── Locate repo root ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="${KPORT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# ── Defaults ──────────────────────────────────────────────────────────────────

DRY_RUN=false
FORCE=false
FILTER_SOURCE=""

SOURCES_FILE="${KPORT_ROOT}/config/sources.yml"
CACHE_FILE="${KPORT_ROOT}/db/sources-cache.json"
MAX_CACHE_AGE_HOURS=24

GITLAB_API="https://invent.kde.org/api/v4"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"

# ── Logging ───────────────────────────────────────────────────────────────────

info()  { echo "[sync-sources] $*"; }
warn()  { echo "[warn]         $*" >&2; }
error() { echo "[error]        $*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)  FILTER_SOURCE="$2"; shift 2 ;;
    --force)   FORCE=true;         shift ;;
    --dry-run) DRY_RUN=true;       shift ;;
    --help)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) error "Unknown option: $1" ;;
  esac
done

# ── Dependency checks ─────────────────────────────────────────────────────────

for cmd in curl python3 jq; do
  command -v "$cmd" &>/dev/null || error "Required command not found: $cmd"
done

# ── GitLab API helpers ────────────────────────────────────────────────────────

gl_get() {
  local url="$1"
  local response http_code
  response=$(curl -sf -w "\n%{http_code}" \
    ${GITLAB_TOKEN:+-H "PRIVATE-TOKEN: ${GITLAB_TOKEN}"} \
    "$url" 2>/dev/null) || true
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "200" ]]; then
    echo "$body"
    return 0
  elif [[ "$http_code" == "429" ]]; then
    warn "Rate limited — sleeping 60s"
    sleep 60
    gl_get "$url"
  else
    warn "HTTP ${http_code} for ${url}"
    return 1
  fi
}

gl_group_id() {
  local group_path="$1"
  local encoded
  encoded=$(python3 -c \
    "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" \
    "$group_path")
  gl_get "${GITLAB_API}/groups/${encoded}" | jq -r '.id // empty'
}

# Fetch all projects in a group, handling pagination.
# Outputs a JSON array.
gl_group_projects_json() {
  local group_id="$1"
  local page=1
  local all="[]"
  while true; do
    local batch
    batch=$(gl_get \
      "${GITLAB_API}/groups/${group_id}/projects?per_page=100&page=${page}&include_subgroups=false") \
      || break
    local count
    count=$(echo "$batch" | jq 'length')
    [[ "$count" -eq 0 ]] && break
    # Merge into all, keeping only the fields we need
    all=$(echo "$all $batch" | jq -s '
      (.[0] + .[1])
      | map({
          id,
          path,
          path_with_namespace,
          default_branch,
          description
        })
    ')
    (( page++ ))
    sleep 0.2
  done
  echo "$all"
}

# ── Cache helpers ─────────────────────────────────────────────────────────────

# Read the current cache, or return an empty structure.
read_cache() {
  if [[ -f "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
  else
    echo '{"generated_at": "", "sources": {}}'
  fi
}

# Check if a cache entry for a group is still fresh.
# Returns 0 (fresh) or 1 (stale/missing).
cache_is_fresh() {
  local group_path="$1"
  local cache="$2"

  local fetched_at
  fetched_at=$(echo "$cache" | \
    jq -r --arg g "$group_path" '.sources[$g].fetched_at // empty')
  [[ -z "$fetched_at" ]] && return 1

  local age_seconds
  age_seconds=$(python3 -c "
from datetime import datetime, timezone
import sys
fetched = datetime.fromisoformat(sys.argv[1].replace('Z', '+00:00'))
now = datetime.now(timezone.utc)
print(int((now - fetched).total_seconds()))
" "$fetched_at" 2>/dev/null) || return 1

  local max_age_seconds=$(( MAX_CACHE_AGE_HOURS * 3600 ))
  [[ "$age_seconds" -lt "$max_age_seconds" ]]
}

# ── sources.yml parser ────────────────────────────────────────────────────────

parse_sources() {
  python3 - "$SOURCES_FILE" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

lines = content.splitlines()
in_sources = in_entry = False
entry = {}

def emit(e):
    if e.get('type') == 'gitlab' and e.get('enabled', 'true') != 'false':
        print("{name}|{base_url}|{group}|{category}|{branch}".format(
            name     = e.get('name', ''),
            base_url = e.get('base_url', 'https://invent.kde.org'),
            group    = e.get('group', ''),
            category = e.get('category', ''),
            branch   = e.get('branch', 'Neon/unstable'),
        ))

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        continue
    if stripped == 'sources:':
        in_sources = True; continue
    if not in_sources:
        continue
    if re.match(r'^\s*-\s+name:', line):
        if in_entry: emit(entry)
        entry = {'name': re.sub(r'^\s*-\s+name:\s*', '', line).strip().strip('"\'') }
        in_entry = True; continue
    if in_entry:
        m = re.match(r'^\s+(type|base_url|group|category|branch|enabled):\s*(.+)', line)
        if m:
            entry[m.group(1)] = m.group(2).strip().strip('"\'')

if in_entry:
    emit(entry)
PYEOF
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  [[ "$DRY_RUN" == "true" ]] && info "Dry run — cache will not be written"
  [[ "$FORCE"   == "true" ]] && info "Force mode — ignoring cache age"
  [[ -n "$GITLAB_TOKEN"   ]] && info "Using authenticated GitLab API"

  local source_lines
  source_lines=$(parse_sources) || error "Failed to parse ${SOURCES_FILE}"

  local cache
  cache=$(read_cache)

  local updated=0
  local skipped=0

  while IFS='|' read -r src_name base_url group category branch; do
    [[ -z "$src_name" ]] && continue
    [[ "$category" == "_meta" ]] && continue

    if [[ -n "$FILTER_SOURCE" && "$src_name" != *"$FILTER_SOURCE"* ]]; then
      continue
    fi

    info "────────────────────────────────────────"
    info "Source: ${src_name}  (group: ${group})"

    # Check cache freshness
    if [[ "$FORCE" != "true" ]] && cache_is_fresh "$group" "$cache"; then
      local project_count
      project_count=$(echo "$cache" | \
        jq -r --arg g "$group" '.sources[$g].projects | length')
      info "  Cache is fresh (${project_count} projects) — skipping"
      (( skipped++ )) || true
      continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      info "  [dry-run] would fetch project list for group ${group}"
      continue
    fi

    # Resolve group ID
    local group_id
    group_id=$(gl_group_id "$group") || {
      warn "  Could not resolve group ID for ${group} — skipping"
      continue
    }
    info "  Group ID: ${group_id}"

    # Fetch projects
    local projects_json
    projects_json=$(gl_group_projects_json "$group_id")
    local project_count
    project_count=$(echo "$projects_json" | jq 'length')
    info "  Fetched ${project_count} projects"

    # Merge into cache
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cache=$(echo "$cache" | jq \
      --arg g "$group" \
      --argjson gid "$group_id" \
      --arg ts "$now" \
      --argjson projects "$projects_json" \
      '.sources[$g] = {
        "group_id":   $gid,
        "fetched_at": $ts,
        "projects":   $projects
      }')

    (( updated++ )) || true
  done <<< "$source_lines"

  if [[ "$DRY_RUN" != "true" && "$updated" -gt 0 ]]; then
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cache=$(echo "$cache" | jq --arg ts "$now" '.generated_at = $ts')
    mkdir -p "$(dirname "$CACHE_FILE")"
    echo "$cache" | jq '.' > "$CACHE_FILE"
    info "────────────────────────────────────────"
    info "Cache written to ${CACHE_FILE}"
  fi

  info "════════════════════════════════════════"
  info "Done — updated: ${updated}  skipped (fresh): ${skipped}"
  info "════════════════════════════════════════"
}

main "$@"
