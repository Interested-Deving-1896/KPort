#!/usr/bin/env bash
#
# setup-runtime.sh
#
# Installs KPort runtime files to the system so pacscripts can find them.
# Must be run once after cloning KPort, and re-run after pulling updates.
#
# Usage:
#   sudo scripts/kport/setup-runtime.sh          # install to /usr/lib/kport/
#   scripts/kport/setup-runtime.sh --user        # install to ~/.local/lib/kport/
#   scripts/kport/setup-runtime.sh --prefix /opt # install to /opt/lib/kport/
#   scripts/kport/setup-runtime.sh --dry-run     # show what would be installed
#
# After --user install, pacscripts won't find the helpers at the default path
# (/usr/lib/kport/use-helpers.sh). Set KPORT_LIB_DIR in your environment and
# the pacscript guard handles it:
#
#   export KPORT_LIB_DIR=~/.local/lib/kport
#
# Runtime files installed:
#   lib/kport/use-helpers.sh  →  <prefix>/lib/kport/use-helpers.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPORT_ROOT="${KPORT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# ── Defaults ──────────────────────────────────────────────────────────────────

PREFIX="/usr"
DRY_RUN=false
USER_INSTALL=false

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)        USER_INSTALL=true; shift ;;
    --prefix)      PREFIX="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --help)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ "$USER_INSTALL" == "true" ]]; then
  PREFIX="${HOME}/.local"
fi

LIB_DEST="${PREFIX}/lib/kport"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { echo "[setup-runtime] $*"; }
dry()   { echo "[dry-run]       $*"; }
error() { echo "[error]         $*" >&2; exit 1; }

install_file() {
  local src="$1" dest_dir="$2" dest_file="$3"
  local dest="${dest_dir}/${dest_file}"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "install ${src} → ${dest}"
    return 0
  fi

  mkdir -p "$dest_dir" || error "Cannot create ${dest_dir} (try sudo or --user)"
  install -m 644 "$src" "$dest" || error "Failed to install ${src} → ${dest}"
  info "  installed ${dest}"
}

# ── Main ──────────────────────────────────────────────────────────────────────

info "KPort runtime setup"
info "  Source : ${KPORT_ROOT}/lib/kport/"
info "  Dest   : ${LIB_DEST}/"
[[ "$DRY_RUN" == "true" ]] && info "  Mode   : dry run"
echo ""

# Verify source files exist
[[ -f "${KPORT_ROOT}/lib/kport/use-helpers.sh" ]] \
  || error "Source file not found: ${KPORT_ROOT}/lib/kport/use-helpers.sh"

# Install runtime library files
install_file \
  "${KPORT_ROOT}/lib/kport/use-helpers.sh" \
  "${LIB_DEST}" \
  "use-helpers.sh"

echo ""
info "Done."

if [[ "$USER_INSTALL" == "true" && "$DRY_RUN" != "true" ]]; then
  echo ""
  info "User install: pacscripts look for /usr/lib/kport/use-helpers.sh by default."
  info "To use the user-installed path, add to your shell profile:"
  info "  export KPORT_LIB_DIR=${LIB_DEST}"
  info "Or symlink: sudo ln -s ${LIB_DEST} /usr/lib/kport"
fi
