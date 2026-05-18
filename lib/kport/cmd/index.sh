#!/usr/bin/env bash
# kport index
#
# Builds a search index from all pacscripts in packages/ and enabled overlays.
# Written to $KPORT_DB/index.json. Called automatically by kport sync.
#
# Usage: kport index [--force]

set -uo pipefail

FORCE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|-f) FORCE=true; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) kport_die "Unknown option: $1" ;;
  esac
done

INDEX_FILE="${KPORT_DB}/index.json"

# Check if index is up to date (newer than all pacscripts)
if [[ "$FORCE" == "false" && -f "$INDEX_FILE" ]]; then
  newest_pkg=$(find "$KPORT_PACKAGES_DIR" -name "*.pacscript" -newer "$INDEX_FILE" 2>/dev/null | head -1)
  if [[ -z "$newest_pkg" ]]; then
    kport_verbose "Search index is up to date."
    exit 0
  fi
fi

kport_info "Building search index..."

# Collect all pacscript paths: overlays first, then main tree
search_dirs=()
if [[ -d "$KPORT_OVERLAYS_DIR" ]]; then
  while IFS= read -r d; do
    [[ "$d" == *"/example" ]] && continue
    search_dirs+=("$d")
  done < <(find "$KPORT_OVERLAYS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi
search_dirs+=("$KPORT_PACKAGES_DIR")

# Build index as newline-delimited JSON records
tmp_index=$(mktemp)
count=0

for search_root in "${search_dirs[@]}"; do
  [[ -d "$search_root" ]] || continue
  while IFS= read -r pacscript; do
    pkgname=$(kport_pacscript_var "$pacscript" pkgname)
    [[ -z "$pkgname" ]] && continue
    pkgver=$(kport_pacscript_var  "$pacscript" pkgver)
    pkgdesc=$(kport_pacscript_var "$pacscript" pkgdesc)
    category=$(kport_pacscript_var "$pacscript" KCATEGORY)
    slot=$(kport_pacscript_var    "$pacscript" KSLOT)
    # Escape for JSON
    pkgname_j=$(printf '%s' "$pkgname" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    pkgver_j=$(printf '%s' "$pkgver"   | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    pkgdesc_j=$(printf '%s' "$pkgdesc" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    cat_j=$(printf '%s' "$category"    | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    slot_j=$(printf '%s' "$slot"       | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    path_j=$(printf '%s' "$pacscript"  | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    printf '{"n":%s,"v":%s,"d":%s,"c":%s,"s":%s,"p":%s}\n' \
      "$pkgname_j" "$pkgver_j" "$pkgdesc_j" "$cat_j" "$slot_j" "$path_j" >> "$tmp_index"
    (( count++ )) || true
  done < <(find "$search_root" -name "*.pacscript" 2>/dev/null | sort)
done

# Wrap as JSON array
mkdir -p "$(dirname "$INDEX_FILE")"
{ echo '['; sed '$!s/$/,/' "$tmp_index"; echo ']'; } > "$INDEX_FILE"
rm -f "$tmp_index"

kport_info "Index built: ${count} packages → ${INDEX_FILE}"
