#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
SCRATCH_WORKSPACE="${AEROSPACE_SCRATCH_WORKSPACE:-S}"
TERMINAL_APP_ID="${AEROSPACE_DROPDOWN_APP_ID:-com.mitchellh.ghostty}"
TERMINAL_TITLE="${AEROSPACE_DROPDOWN_TITLE:-DropTerminal}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

focused_workspace="$($AERO_BIN list-workspaces --focused --format '%{workspace}' 2>/dev/null || true)"
[ -n "$focused_workspace" ] || exit 0

find_dropdown_window() {
  "$AERO_BIN" list-windows --all --format '%{window-id}%{tab}%{workspace}%{tab}%{app-bundle-id}%{tab}%{window-title}' 2>/dev/null |
    awk -F'\t' -v app="$TERMINAL_APP_ID" -v title="$TERMINAL_TITLE" '
      BEGIN {
        app=tolower(app)
        title=tolower(title)
      }
      {
        if (tolower($3) == app && index(tolower($4), title) > 0) {
          print $1 "\t" $2
          exit
        }
      }
    '
}

apply_dropdown_geometry() {
  local bounds_csv
  bounds_csv="$(osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Finder"
  set b to bounds of window of desktop
  set leftEdge to item 1 of b
  set topEdge to item 2 of b
  set rightEdge to item 3 of b
  set bottomEdge to item 4 of b
  return leftEdge & "," & topEdge & "," & rightEdge & "," & bottomEdge
end tell
APPLESCRIPT
)"

  local left top right bottom
  left="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $1); print $1}')"
  top="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $2); print $2}')"
  right="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $3); print $3}')"
  bottom="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $4); print $4}')"

  if ! [[ "$left" =~ ^-?[0-9]+$ && "$top" =~ ^-?[0-9]+$ && "$right" =~ ^-?[0-9]+$ && "$bottom" =~ ^-?[0-9]+$ ]]; then
    return
  fi

  local screen_w screen_h target_w target_h target_x target_y
  screen_w=$((right - left))
  screen_h=$((bottom - top))
  target_w=$((screen_w * 88 / 100))
  target_h=$((screen_h * 40 / 100))
  target_x=$((left + (screen_w - target_w) / 2))
  target_y=$((top + 36))

  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "System Events"
  set frontProc to first process whose frontmost is true
  if (count of windows of frontProc) is 0 then return
  set focusedWin to value of attribute "AXFocusedWindow" of frontProc
  if focusedWin is missing value then return
  set value of attribute "AXPosition" of focusedWin to {$target_x, $target_y}
  set value of attribute "AXSize" of focusedWin to {$target_w, $target_h}
end tell
APPLESCRIPT
}

window_record="$(find_dropdown_window || true)"
window_id="$(printf '%s' "$window_record" | awk -F'\t' '{print $1}')"
window_workspace="$(printf '%s' "$window_record" | awk -F'\t' '{print $2}')"

if [ -n "$window_id" ]; then
  if [ "$window_workspace" = "$focused_workspace" ]; then
    "$AERO_BIN" move-node-to-workspace --window-id "$window_id" "$SCRATCH_WORKSPACE" >/dev/null 2>&1 || true
    exit 0
  fi

  "$AERO_BIN" move-node-to-workspace --window-id "$window_id" "$focused_workspace" >/dev/null 2>&1 || true
  "$AERO_BIN" focus --window-id "$window_id" >/dev/null 2>&1 || true
  "$AERO_BIN" layout --window-id "$window_id" floating >/dev/null 2>&1 || true
  apply_dropdown_geometry
  exit 0
fi

open -na Ghostty --args --title "$TERMINAL_TITLE" >/dev/null 2>&1 || open -na Ghostty >/dev/null 2>&1 || true

for _ in {1..30}; do
  sleep 0.1
  window_record="$(find_dropdown_window || true)"
  window_id="$(printf '%s' "$window_record" | awk -F'\t' '{print $1}')"
  [ -n "$window_id" ] && break
 done

[ -n "$window_id" ] || exit 0
"$AERO_BIN" move-node-to-workspace --window-id "$window_id" "$focused_workspace" >/dev/null 2>&1 || true
"$AERO_BIN" focus --window-id "$window_id" >/dev/null 2>&1 || true
"$AERO_BIN" layout --window-id "$window_id" floating >/dev/null 2>&1 || true
apply_dropdown_geometry
