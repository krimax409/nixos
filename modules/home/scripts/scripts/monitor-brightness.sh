#!/usr/bin/env bash
# monitor-brightness — DDC/CI brightness control per niri output.
# Usage:
#   monitor-brightness list          -> "OUTPUT:CURRENT:MAX" lines
#   monitor-brightness get DP-1      -> current value (0-MAX)
#   monitor-brightness set DP-1 50   -> set value (0-100 percent)
# Requires: ddcutil, i2c-dev kernel module, user in i2c group.
# Note: no `pipefail` — ddcutil legitimately fails for monitors without
# DDC/CI support (e.g. old Samsung over HDMI), and pipefail + set -e kills
# the whole script on such a pipeline even when we handle the empty output.
set -eu

command -v ddcutil > /dev/null 2>&1 || exit 1
command -v jq > /dev/null 2>&1 || exit 1

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/monitor-brightness"
mkdir -p "$CACHE_DIR"
VCP_BRIGHTNESS=10

refresh_maps() {
    niri msg -j outputs > "$CACHE_DIR/outputs.json" 2> /dev/null || return 1
    ddcutil detect > "$CACHE_DIR/detect.txt" 2> /dev/null || return 1
    : > "$CACHE_DIR/busmap"

    local bus="" model=""
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            *"I2C bus:"*)
                bus="${line##*i2c-}"
                bus="${bus%%[!0-9]*}"
                ;;
            *"Model:"*)
                model="${line#*:}"
                model="${model#"${model%%[![:space:]]*}"}"
                model="${model%"${model##*[![:space:]]}"}"
                ;;
            "")
                if [ -n "$model" ] && [ -n "$bus" ]; then
                    local out
                    out=$(jq -r --arg m "$model" \
                        'to_entries[] | select((.value.model // "") == $m) | .key' \
                        "$CACHE_DIR/outputs.json" 2> /dev/null | head -n1)
                    if [ -n "$out" ]; then
                        printf '%s\t%s\n' "$out" "$bus" >> "$CACHE_DIR/busmap"
                    fi
                fi
                bus=""
                model=""
                ;;
        esac
    done < "$CACHE_DIR/detect.txt"
}

bus_for() {
    local out="$1" map="$CACHE_DIR/busmap"
    if [ ! -s "$map" ] || [ -n "$(find "$CACHE_DIR" -name busmap -mmin +2 2> /dev/null)" ]; then
        refresh_maps || true
    fi
    [ -s "$map" ] && awk -v o="$out" -F'\t' '$1 == o { print $2; exit }' "$map"
}

case "${1:-}" in
    list)
        [ -s "$CACHE_DIR/busmap" ] || refresh_maps || true
        while IFS=$'\t' read -r out bus; do
            val=$(ddcutil getvcp "$VCP_BRIGHTNESS" --bus "$bus" 2> /dev/null |
                awk -F'=' '/current value/ { gsub(/[^0-9]/, "", $2); print $2; exit }')
            if [ -n "${val:-}" ]; then
                printf '%s:%s:100\n' "$out" "$val"
            fi
        done < "$CACHE_DIR/busmap"
        exit 0
        ;;
    get)
        bus=$(bus_for "${2:-}")
        [ -n "${bus:-}" ] || exit 1
        ddcutil getvcp "$VCP_BRIGHTNESS" --bus "$bus" 2> /dev/null |
            awk -F'=' '/current value/ { gsub(/[^0-9]/, "", $2); print $2; exit }'
        ;;
    set)
        bus=$(bus_for "${2:-}")
        [ -n "${bus:-}" ] || exit 1
        val="${3:-}"
        [ -n "$val" ] || exit 1
        ddcutil setvcp "$VCP_BRIGHTNESS" "$val" --bus "$bus" > /dev/null 2>&1 || exit 1
        ;;
    *)
        echo "usage: monitor-brightness [list|get OUTPUT|set OUTPUT VALUE]" >&2
        exit 2
        ;;
esac
