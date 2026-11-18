#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
root=$(mktemp -d)
trap 'rm -rf -- "$root"' EXIT
mkdir "$root/bin" "$root/runtime"
export PATH="$root/bin:$PATH" XDG_RUNTIME_DIR="$root/runtime"
export WALLPAPER_VIDEO_2K="$root/2k.mp4" WALLPAPER_VIDEO_FULLHD="$root/fullhd.mp4"
export FIXTURE_LOG="$root/mpvpaper.log" HYPRLAND_INSTANCE_SIGNATURE=fixture
unset WALLPAPER_VIDEO WALLPAPER_STATE_DIR

touch "$WALLPAPER_VIDEO_2K" "$WALLPAPER_VIDEO_FULLHD"
cat > "$root/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == '-j monitors' ]] || exit 2
printf '%s\n' '[{"name":"eDP-1","width":1920,"height":1200,"scale":1,"transform":0},{"name":"DP-3","width":2560,"height":1440,"scale":1,"transform":1}]'
EOF
cat > "$root/bin/niri" <<'EOF'
#!/usr/bin/env bash
exit 2
EOF
cat > "$root/bin/mpvpaper" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${*: -2}" >> "$FIXTURE_LOG"
exec sleep 10
EOF
cat > "$root/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$root/bin/"*
script="$repo_root/modules/home/scripts/scripts/wallpaper-toggle.sh"
if ! bash "$script"; then
  printf '%s\n' 'FAIL: wallpaper-toggle could not start using the Hyprland monitor fixture' >&2
  exit 1
fi
for _ in {1..30}; do
  [[ -f "$FIXTURE_LOG" ]] && [[ $(wc -l < "$FIXTURE_LOG") -eq 2 ]] && break
  sleep 0.05
done
bash "$script"
[[ $(sort "$FIXTURE_LOG") == "DP-3 $WALLPAPER_VIDEO_2K"$'\n'"eDP-1 $WALLPAPER_VIDEO_FULLHD" ]]
printf '%s\n' 'PASS: Hyprland output names and resolution-specific wallpaper variants'
