#!/usr/bin/env bash

# Alt-Tab that preserves fullscreen state
# Usage: alt-tab.sh [prev]

FS=$(hyprctl activewindow -j | jq -r '.fullscreen')
CYCLE="dispatch cyclenext${1:+ prev}"

if [ "$FS" = "2" ]; then
  # Disable animation, switch + refullscreen in one frame, re-enable
  hyprctl --batch "keyword animations:enabled 0; $CYCLE; dispatch bringactivetotop; dispatch fullscreen 0; keyword animations:enabled 1"
elif [ "$FS" = "1" ]; then
  hyprctl --batch "keyword animations:enabled 0; $CYCLE; dispatch bringactivetotop; dispatch fullscreen 1; keyword animations:enabled 1"
else
  hyprctl --batch "$CYCLE; dispatch bringactivetotop"
fi
