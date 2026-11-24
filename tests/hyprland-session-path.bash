#!/usr/bin/env bash
set -euo pipefail

launcher=${1:-/run/current-system/sw/bin/hyprland-laptop}
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin"

# Check both hand-offs without starting a second graphical session.
exec() {
  local sudo_path
  sudo_path=$(command -v sudo)
  if [[ $sudo_path != /run/wrappers/bin/sudo ]]; then
    printf '%s would resolve sudo to %s\n' "${1##*/}" "$sudo_path" >&2
    return 1
  fi

  case "$1" in
    */uwsm) source "${!#}" ;;
    */start-hyprland) ;;
    *) printf 'Unexpected session command: %s\n' "$1" >&2; return 1 ;;
  esac
}

source "$launcher"
