#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
defaults="$repo_root/configs/quickshell/win11-start-menu/defaults.json"
qml="$repo_root/configs/quickshell/win11-start-menu/shell.qml"

test "$(jq -r '.version' "$defaults")" = "2"
test "$(jq -r '(.pinned | type)' "$defaults")" = "array"
test "$(jq -r 'has("recommended")' "$defaults")" = "false"
test "$(jq -r '(.quickActions | type)' "$defaults")" = "array"
test "$(jq -r '(.quickActions | length) >= 3' "$defaults")" = "true"
test "$(jq -r 'all(.quickActions[]; has("id") and has("label") and has("glyph"))' "$defaults")" = "true"
test "$(jq -r '(.powerActions | type)' "$defaults")" = "array"
test "$(jq -r 'all(.powerActions[]; has("id") and has("label") and (.command | type) == "array")' "$defaults")" = "true"

grep -q 'property var quickActions' "$qml"
grep -q 'property var powerActions' "$qml"
grep -q 'function executeConfiguredAction' "$qml"
grep -q 'function togglePowerMenu' "$qml"
grep -q 'function setAppsView' "$qml"
grep -q 'target: "start-menu"' "$qml"
grep -q 'property bool searchMode' "$qml"
grep -q 'property var contextMenuActions' "$qml"
grep -q 'function clearSearch' "$qml"
grep -q 'function openContextMenu' "$qml"
grep -q 'function executeContextAction' "$qml"
grep -q 'Результаты поиска' "$qml"
grep -q 'label: "Закрепить"' "$qml"
grep -q 'label: "Открепить"' "$qml"
grep -q 'var actions = \[' "$qml"
grep -q 'contextMenuActions = actions' "$qml"
! grep -q 'contextMenuActions\.push' "$qml"
! grep -q 'property var recommendedApplications' "$qml"
! grep -q 'property var frequentApplications' "$qml"
! grep -q 'Рекомендуем\|Часто используемые' "$qml"
! grep -q 'frequentMouse' "$qml"
grep -q 'text: "Приложения"' "$qml"
grep -q 'model: root.applications' "$qml"
grep -q 'width: Math.min(920, parent.width - 64)' "$qml"
grep -q 'height: Math.min(720, parent.height - 64)' "$qml"
! grep -q 'width: parent.width - 18' "$qml"
! grep -q 'height: Math.max(620, parent.height - 16)' "$qml"
grep -q 'Keys.onDownPressed' "$qml"
grep -q 'acceptedButtons: Qt.LeftButton | Qt.RightButton' "$qml"
! grep -q 'text: "▯"' "$qml"

# Keep the menu surface opaque and chromatically neutral so wallpaper colors do
# not bleed through the shell and the power popover follows the same palette.
grep -q 'readonly property color cardColor: "#f21b1e21"' "$qml"
grep -q 'readonly property color accentColor: "#b6c5ff"' "$qml"
grep -q 'color: root.menuBgColor' "$qml"
! grep -q '#f01f211f\|#322f2caa\|#f82a2c2a' "$qml"

printf '%s\n' 'win11-start-menu: pass'
