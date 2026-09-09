#!/usr/bin/env bash

set -euo pipefail

video_2k_path="${WALLPAPER_VIDEO_2K:-$HOME/Videos/Wallpapers/nangong-yu-2k60.mp4}"
video_fullhd_path="${WALLPAPER_VIDEO_FULLHD:-$HOME/Videos/Wallpapers/nangong-yu-fullhd60.mp4}"
video_override="${WALLPAPER_VIDEO:-}"
state_dir="${WALLPAPER_STATE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/wallpaper-toggle}"
pid_file="$state_dir/mpvpaper.pids"
log_file="$state_dir/mpvpaper.log"

mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock -n 9 || exit 0

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Wallpaper" "$1" "$2" -t 3000 || true
    fi
}

wallpaper_running() {
    local pid

    [[ -s "$pid_file" ]] || return 1
    while read -r pid; do
        [[ "$pid" =~ ^[0-9]+$ ]] || continue
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    done < "$pid_file"
    return 1
}

stop_wallpaper() {
    local pid

    if [[ -f "$pid_file" ]]; then
        while read -r pid; do
            [[ "$pid" =~ ^[0-9]+$ ]] || continue
            kill "$pid" 2>/dev/null || true
        done < "$pid_file"
        rm -f "$pid_file"
    fi
}

start_wallpaper() {
    local index=0
    local output
    local width
    local height
    local selected_video
    local mpv_options
    local entry
    local -a output_info
    local -a wallpaper_targets

    if ! command -v mpvpaper >/dev/null 2>&1; then
        notify "Видеообои" "mpvpaper не установлен"
        return 1
    fi
    if ! command -v niri >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        notify "Видеообои" "Не найдены niri или jq"
        return 1
    fi

    mapfile -t output_info < <(niri msg -j outputs | jq -r 'to_entries[] | [.key, (.value.logical.width // 0), (.value.logical.height // 0)] | @tsv')
    if ((${#output_info[@]} == 0)); then
        notify "Видеообои" "Niri не вернул список мониторов"
        return 1
    fi

    for entry in "${output_info[@]}"; do
        IFS=$'\t' read -r output width height <<< "$entry"
        if [[ -n "$video_override" ]]; then
            selected_video="$video_override"
        elif [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] && ((width >= 2560 || height >= 1440)); then
            selected_video="$video_2k_path"
        else
            selected_video="$video_fullhd_path"
        fi
        if [[ ! -f "$selected_video" ]]; then
            notify "Видеообои" "Файл не найден: $selected_video"
            return 1
        fi
        wallpaper_targets+=("$output"$'\t'"$selected_video")
    done

    : > "$pid_file"
    : > "$log_file"
    for entry in "${wallpaper_targets[@]}"; do
        IFS=$'\t' read -r output selected_video <<< "$entry"
        mpv_options="--hwdec=auto --loop-file=inf --no-osc --no-osd-bar"
        if ((index > 0)); then
            mpv_options+=" --no-audio"
        fi
        mpvpaper -p -a FULL -l background -o "$mpv_options" "$output" "$selected_video" >>"$log_file" 2>&1 9>&- &
        echo "$!" >> "$pid_file"
        ((index += 1))
    done

    notify "Видеообои" "Включены на ${#wallpaper_targets[@]} мониторах"
}

if wallpaper_running; then
    stop_wallpaper
    notify "Видеообои" "Выключены"
else
    start_wallpaper
fi
