#!/usr/bin/env bash

# Скрипт для переключения между KDE Plasma и Hyprland

set -e

show_usage() {
    echo "Usage: switch-de [kde|hyprland|status]"
    echo ""
    echo "Commands:"
    echo "  kde       - Switch to KDE Plasma"
    echo "  hyprland  - Switch to Hyprland"
    echo "  status    - Show current session"
    echo ""
    echo "The system will remember your choice and auto-login to it."
}

get_current_session() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP"
    else
        echo "Unknown (not in graphical session)"
    fi
}

switch_session() {
    local session="$1"
    local sddm_state_conf="$HOME/.cache/sddm-state.conf"

    # Создаем директорию если её нет
    mkdir -p "$(dirname "$sddm_state_conf")"

    case "$session" in
        kde | plasma)
            echo "[General]" > "$sddm_state_conf"
            echo "Session=plasma" >> "$sddm_state_conf"
            echo "✓ Switched to KDE Plasma"
            echo "  Logout to apply changes (run: loginctl terminate-session \$XDG_SESSION_ID)"
            ;;
        hyprland)
            echo "[General]" > "$sddm_state_conf"
            echo "Session=hyprland" >> "$sddm_state_conf"
            echo "✓ Switched to Hyprland"
            echo "  Logout to apply changes (run: loginctl terminate-session \$XDG_SESSION_ID)"
            ;;
        *)
            echo "Error: Unknown session type '$session'"
            show_usage
            exit 1
            ;;
    esac
}

case "${1:-}" in
    kde | plasma)
        switch_session "kde"
        ;;
    hyprland)
        switch_session "hyprland"
        ;;
    status)
        echo "Current session: $(get_current_session)"
        if [ -f "$HOME/.cache/sddm-state.conf" ]; then
            echo "Next session will be:"
            cat "$HOME/.cache/sddm-state.conf"
        fi
        ;;
    -h | --help | help)
        show_usage
        ;;
    *)
        echo "Error: Invalid command"
        echo ""
        show_usage
        exit 1
        ;;
esac
