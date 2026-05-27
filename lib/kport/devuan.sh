#!/usr/bin/env bash
# lib/kport/devuan.sh
#
# Devuan / non-systemd support helpers for KPort.
#
# Sourced by commands that need to be init-system-aware (install, detect).
# Never executed directly.
#
# Devuan is a Debian fork that replaces systemd with sysvinit/OpenRC/runit.
# KDE Neon packages that hard-depend on systemd cannot be installed as-is;
# this module detects the init system and applies substitutions or masks
# defined in config/pangea.yml (devuan_substitutions / systemd_dependent).
#
# Detection strategy (in order):
#   1. /run/systemd/private exists → systemd
#   2. /sbin/init --version output contains "systemd" → systemd
#   3. /etc/os-release VARIANT_ID=devuan → devuan
#   4. dpkg -l sysvinit-core installed → sysvinit
#   5. command -v openrc → openrc
#   6. command -v runit → runit
#   7. Fallback → unknown (treated as systemd-compatible)

[[ -n "${_KPORT_DEVUAN_LOADED:-}" ]] && return 0
_KPORT_DEVUAN_LOADED=1

# ── Init system detection ─────────────────────────────────────────────────────

# Returns the detected init system: systemd | sysvinit | openrc | runit | unknown
kport_detect_init() {
  # Fastest check: systemd leaves a private socket dir at boot
  if [[ -d /run/systemd/private ]]; then
    echo "systemd"
    return 0
  fi

  # Check /sbin/init --version (works on most systems)
  if /sbin/init --version 2>&1 | grep -q systemd; then
    echo "systemd"
    return 0
  fi

  # Devuan explicitly sets VARIANT_ID in os-release
  if [[ -f /etc/os-release ]]; then
    local variant_id
    variant_id=$(. /etc/os-release 2>/dev/null; echo "${VARIANT_ID:-}")
    if [[ "$variant_id" == "devuan" ]]; then
      # Determine which init Devuan is using
      if command -v openrc &>/dev/null && openrc --version &>/dev/null 2>&1; then
        echo "openrc"
      elif command -v runit &>/dev/null; then
        echo "runit"
      else
        echo "sysvinit"
      fi
      return 0
    fi
  fi

  # sysvinit-core package installed (Debian/Devuan)
  if dpkg -l sysvinit-core &>/dev/null 2>&1; then
    echo "sysvinit"
    return 0
  fi

  # OpenRC (Gentoo, Alpine, some Devuan configs)
  if command -v openrc &>/dev/null && openrc --version &>/dev/null 2>&1; then
    echo "openrc"
    return 0
  fi

  # runit (Void Linux, some Devuan configs)
  if command -v runit &>/dev/null; then
    echo "runit"
    return 0
  fi

  echo "unknown"
}

# Returns 0 if running under systemd, 1 otherwise.
kport_is_systemd() {
  [[ "$(kport_detect_init)" == "systemd" ]]
}

# Returns 0 if running on Devuan (any init).
kport_is_devuan() {
  if [[ -f /etc/os-release ]]; then
    local variant_id
    variant_id=$(. /etc/os-release 2>/dev/null; echo "${VARIANT_ID:-}")
    [[ "$variant_id" == "devuan" ]] && return 0
  fi
  # Also check /etc/devuan_version (older Devuan releases)
  [[ -f /etc/devuan_version ]] && return 0
  return 1
}

# ── Pangea config helpers ─────────────────────────────────────────────────────

# Path to pangea.yml (relative to KPORT_ROOT)
_KPORT_PANGEA_YML="${KPORT_ROOT}/config/pangea.yml"

# Returns 0 if the package is listed as systemd-dependent in pangea.yml.
# Falls back to a hardcoded list if pangea.yml is not available.
kport_systemd_dependent() {
  local pkg="$1"

  if [[ -f "$_KPORT_PANGEA_YML" ]] && command -v python3 &>/dev/null; then
    python3 - "$_KPORT_PANGEA_YML" "$pkg" <<'PYEOF'
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1]))
pkg = sys.argv[2]
deps = cfg.get('systemd_dependent', [])
sys.exit(0 if pkg in deps else 1)
PYEOF
    return $?
  fi

  # Hardcoded fallback (mirrors pangea.yml systemd_dependent list)
  local -a _SYSTEMD_DEPS=(
    sddm sddm-kcm powerdevil bluedevil kwallet-pam ksshaskpass
    plasma-nm plasma-pa kscreen kgamma ksystemstats libksysguard
    plasma-systemmonitor drkonqi polkit-kde-agent-1
    xdg-desktop-portal-kde plasma-disks plasma-firewall
    plasma-thunderbolt plasma-vault plasma-welcome
  )
  local dep
  for dep in "${_SYSTEMD_DEPS[@]}"; do
    [[ "$dep" == "$pkg" ]] && return 0
  done
  return 1
}

# Returns the Devuan substitute for a package, or empty string if masked.
# Outputs nothing if no substitution is defined (package is allowed as-is).
kport_devuan_substitute() {
  local pkg="$1"

  if [[ -f "$_KPORT_PANGEA_YML" ]] && command -v python3 &>/dev/null; then
    python3 - "$_KPORT_PANGEA_YML" "$pkg" <<'PYEOF'
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1]))
pkg = sys.argv[2]
subs = cfg.get('devuan_substitutions', {})
if pkg in subs:
    print(subs[pkg])   # empty string = mask
    sys.exit(0)
sys.exit(1)            # no substitution defined
PYEOF
    return $?
  fi

  # Hardcoded fallback
  case "$pkg" in
    sddm)       echo "lightdm";              return 0 ;;
    powerdevil) echo "";                     return 0 ;;
    bluedevil)  echo "";                     return 0 ;;
    kwallet-pam) echo "";                    return 0 ;;
    plasma-nm)  echo "network-manager-gnome"; return 0 ;;
    plasma-pa)  echo "pavucontrol";          return 0 ;;
  esac
  return 1
}

# ── Install-time gate ─────────────────────────────────────────────────────────

# Called by kport install before building a package.
# On non-systemd systems, checks if the package is systemd-dependent and:
#   - If a substitute exists: prints a warning and returns 2 (caller should
#     install the substitute instead)
#   - If masked (empty substitute): prints a warning and returns 1 (skip)
#   - If no substitution defined: returns 0 (allow, but warn)
#
# Returns:
#   0 — proceed normally
#   1 — skip this package (masked on this init system)
#   2 — install substitute instead (substitute name written to stdout)
kport_devuan_gate() {
  local pkg="$1"

  # Nothing to do on systemd
  kport_is_systemd && return 0

  # Package not systemd-dependent — allow
  kport_systemd_dependent "$pkg" || return 0

  local init
  init="$(kport_detect_init)"

  # Check for a defined substitution
  local substitute
  if substitute="$(kport_devuan_substitute "$pkg")"; then
    if [[ -z "$substitute" ]]; then
      kport_warn "${pkg}: masked on ${init} (systemd-dependent, no substitute)"
      kport_warn "  Remove from world or add to package.unmask to suppress this warning"
      return 1
    else
      kport_warn "${pkg}: systemd-dependent — substituting with '${substitute}' on ${init}"
      echo "$substitute"
      return 2
    fi
  fi

  # No substitution defined — warn but allow
  kport_warn "${pkg}: systemd-dependent (running on ${init}) — may not function correctly"
  kport_warn "  Add a devuan_substitutions entry in config/pangea.yml to suppress this"
  return 0
}

# ── Channel variant ───────────────────────────────────────────────────────────

# Returns the effective KPort channel for the current system.
# On Devuan, appends "-devuan" to signal that systemd-dep filtering is active.
# This is informational only — the underlying Neon archive channel is unchanged.
kport_effective_channel() {
  local base_channel="${KPORT_NEON_CHANNEL:-stable}"
  if kport_is_devuan; then
    echo "${base_channel}-devuan"
  else
    echo "$base_channel"
  fi
}
