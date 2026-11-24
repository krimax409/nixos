#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  wallpaper)
    here=$(cd -- "$(dirname -- "$0")" && pwd -P)
    exec bash "$here/../../modules/home/scripts/scripts/wallpaper-toggle.sh"
    ;;
  logout)
    answer=$(printf 'Остаться\nВыйти\n' | noctalia dmenu -p 'Выйти из Hyprland?') || exit 0
    if [[ "$answer" == Выйти ]]; then hyprctl dispatch 'hl.dsp.exit()'; fi
    exit 0
    ;;
  capture-region)
    geometry=$(slurp -b '#18181899' -c '#d6d6d6' -w 2) || exit 0
    [[ -n "$geometry" ]] || exit 0
    options=(-g "$geometry")
    ;;
  capture-output)
    output=$(hyprctl -j monitors | jq -er '.[] | select(.focused) | .name')
    options=(-o "$output")
    ;;
  capture-window)
    geometry=$(hyprctl -j activewindow | jq -er 'select(.at and .size) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"') || exit 0
    options=(-g "$geometry")
    ;;
  *) exit 2 ;;
esac

umask 077
dir="$HOME/Pictures/Screenshots"
mkdir -p -- "$dir"
file="$dir/$(date '+%Y-%m-%d %H-%M-%S').png"
if [[ -e "$file" ]]; then file="$dir/$(date '+%Y-%m-%d %H-%M-%S-%N').png"; fi
if ! timeout 10s grim "${options[@]}" "$file"; then
  rm -f -- "$file"
  exit 1
fi
wl-copy --type image/png < "$file"
notify-send --app-name='Снимки экрана' --icon="$file" 'Снимок сохранён' "${file##*/}" || true
