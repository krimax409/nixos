#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/modules/home/scripts/scripts/wallpaper-toggle.sh"
test_root=$(mktemp -d)
fake_bin="$test_root/bin"
runtime_dir="$test_root/runtime"
mkdir -p "$fake_bin" "$runtime_dir"
trap 'kill $(jobs -p) 2>/dev/null || true; rm -rf "$test_root"' EXIT

cat > "$fake_bin/niri" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '{"HDMI-A-1":{"logical":{"width":1920,"height":1080}},"DP-1":{"logical":{"width":2560,"height":1440}}}'
EOF

cat > "$fake_bin/mpvpaper" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${WALLPAPER_TEST_LOG:?}"
trap 'exit 0' TERM INT
while :; do sleep 1; done
EOF

cat > "$fake_bin/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$fake_bin"/*
video_2k="$test_root/video-2k.mp4"
video_fullhd="$test_root/video-fullhd.mp4"
touch "$video_2k" "$video_fullhd"
log="$test_root/mpvpaper.log"

run_toggle() {
  PATH="$fake_bin:$PATH" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    WALLPAPER_VIDEO_2K="$video_2k" \
    WALLPAPER_VIDEO_FULLHD="$video_fullhd" \
    WALLPAPER_TEST_LOG="$log" \
    bash "$script"
}

run_toggle
sleep 0.1
test "$(wc -l < "$log")" -eq 2
grep -q -- 'HDMI-A-1' "$log"
grep -q -- 'DP-1' "$log"
grep -q -- '--hwdec=auto' "$log"
grep -q -- "$video_2k" "$log"
grep -q -- "$video_fullhd" "$log"
grep -q -- '--no-audio' "$log"
grep -q -- '-p -a FULL' "$log"
test -s "$runtime_dir/wallpaper-toggle/mpvpaper.pids"

run_toggle
test ! -e "$runtime_dir/wallpaper-toggle/mpvpaper.pids"

printf '%s\n' 'wallpaper-toggle: pass'
