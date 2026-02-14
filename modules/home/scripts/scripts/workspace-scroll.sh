#!/usr/bin/env bash

# Non-wrapping workspace scroll
# Usage: workspace-scroll.sh [+1|-1]

DIR="${1:?Usage: workspace-scroll.sh [+1|-1]}"

CURRENT=$(hyprctl activeworkspace -j)
MONITOR=$(echo "$CURRENT" | jq -r '.monitor')
WS_ID=$(echo "$CURRENT" | jq -r '.id')

WORKSPACES=$(hyprctl workspaces -j | jq -r "[.[] | select(.monitor == \"$MONITOR\") | .id] | sort")
FIRST=$(echo "$WORKSPACES" | jq '.[0]')
LAST=$(echo "$WORKSPACES" | jq '.[-1]')

# Don't wrap: stop at edges
if [ "$DIR" = "+1" ] && [ "$WS_ID" = "$LAST" ]; then
  exit 0
elif [ "$DIR" = "-1" ] && [ "$WS_ID" = "$FIRST" ]; then
  exit 0
fi

hyprctl dispatch workspace m${DIR}
