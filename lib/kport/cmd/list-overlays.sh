#!/usr/bin/env bash
# kport list-overlays
#
# Lists all overlay repositories defined in config/repositories.yml,
# showing their name, priority, enabled state, URL, and local path.
#
# Usage: kport list-overlays [options]
#
# Options:
#   --enabled-only   Show only enabled overlays (default: show all)
#   --short          Print only overlay names, one per line
#   --help

set -uo pipefail

ENABLED_ONLY=false
SHORT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enabled-only) ENABLED_ONLY=true; shift ;;
    --short)        SHORT=true;        shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    -*) kport_die "Unknown option: $1" ;;
    *)  kport_die "Unexpected argument: $1" ;;
  esac
done

REPOS_FILE="${KPORT_CONF}/repositories.yml"
[[ -f "$REPOS_FILE" ]] || REPOS_FILE="${KPORT_CONFIG_DIR}/repositories.yml"
[[ -f "$REPOS_FILE" ]] || kport_die "repositories.yml not found"

# Parse all entries (enabled and disabled) from repositories.yml
# Emits: name|priority|enabled|url|branch|local_path|description
_parse_all_overlays() {
  python3 - "$REPOS_FILE" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

lines = content.splitlines()
in_repos = in_entry = False
entries = []
entry = {}

def finish(e):
    if not e:
        return
    local_path = e.get('local_path', '') or 'overlays/' + e.get('name', 'unknown')
    entries.append({
        'name':        e.get('name', ''),
        'priority':    int(e.get('priority', 0)),
        'enabled':     str(e.get('enabled', 'true')).lower(),
        'url':         e.get('url', ''),
        'branch':      e.get('branch', 'main'),
        'local_path':  local_path,
        'description': e.get('description', ''),
    })

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        continue
    if stripped == 'repositories:':
        in_repos = True; continue
    if not in_repos:
        continue
    if re.match(r'^\s*-\s+name:', line):
        if in_entry: finish(entry)
        entry = {'name': re.sub(r'^\s*-\s+name:\s*', '', line).strip().strip('"\'') }
        in_entry = True; continue
    if in_entry:
        m = re.match(r'^\s+(url|branch|local_path|enabled|priority|auto_sync|description):\s*(.+)', line)
        if m:
            entry[m.group(1)] = m.group(2).strip().strip('"\'')

if in_entry:
    finish(entry)

for e in sorted(entries, key=lambda x: -x['priority']):
    print("{name}|{priority}|{enabled}|{url}|{branch}|{local_path}|{description}".format(**e))
PYEOF
}

count=0; enabled_count=0

while IFS='|' read -r name priority enabled url branch local_path description; do
  [[ -z "$name" ]] && continue

  if [[ "$ENABLED_ONLY" == "true" && "$enabled" != "true" ]]; then
    continue
  fi

  (( count++ )) || true
  [[ "$enabled" == "true" ]] && (( enabled_count++ )) || true

  if [[ "$SHORT" == "true" ]]; then
    echo "$name"
    continue
  fi

  # Resolve local path relative to KPORT_ROOT
  if [[ "$local_path" != /* ]]; then
    local_path="${KPORT_ROOT}/${local_path}"
  fi

  # Status indicator
  if [[ "$enabled" == "true" ]]; then
    status="${C_GREEN}enabled${C_RESET} "
  else
    status="${C_DIM}disabled${C_RESET}"
  fi

  # Cloned indicator
  if [[ -d "${local_path}/.git" ]]; then
    cloned="${C_GREEN}✔ cloned${C_RESET}"
  elif [[ -d "$local_path" ]]; then
    cloned="${C_YELLOW}local${C_RESET}  "
  else
    cloned="${C_DIM}not cloned${C_RESET}"
  fi

  echo -e "  ${C_BOLD}${name}${C_RESET}  [${status}]  priority=${priority}  ${cloned}"
  [[ -n "$description" ]] && echo -e "    ${C_DIM}${description}${C_RESET}"
  kport_kv "URL"    "${url:-(local only)}"
  kport_kv "Branch" "$branch"
  kport_kv "Path"   "$local_path"
  echo ""

done < <(_parse_all_overlays)

if [[ "$SHORT" != "true" ]]; then
  if [[ "$count" -eq 0 ]]; then
    kport_info "No overlays registered in repositories.yml"
  else
    echo -e "${C_DIM}${count} overlay(s) registered  |  ${enabled_count} enabled${C_RESET}"
  fi
fi
