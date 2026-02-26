#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
STATE_FILE="$STATE_DIR/last-focused-window-id"
ORIENTATION_FILE="$STATE_DIR/last-split-orientation"
SIDE_FILE="$STATE_DIR/last-split-side"
RUNTIME_STATE_FILE="$STATE_DIR/auto-split-state.tsv"
SPLIT_WIDTH_MULTIPLIER="${HYPR_DWINDLE_SPLIT_WIDTH_MULTIPLIER:-1.0}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$STATE_DIR"

focused_window_id="$("$AERO_BIN" list-windows --focused --format '%{window-id}' 2>/dev/null || true)"
focused_workspace="$("$AERO_BIN" list-windows --focused --format '%{workspace}' 2>/dev/null || true)"

[ -n "$focused_window_id" ] || exit 0
[ -n "$focused_workspace" ] || exit 0

window_count="$("$AERO_BIN" list-windows --workspace "$focused_workspace" --count 2>/dev/null || echo 0)"
[[ "$window_count" =~ ^[0-9]+$ ]] || window_count=0

last_focused_window_id=""
if [ -f "$STATE_FILE" ]; then
  last_focused_window_id="$(cat "$STATE_FILE" 2>/dev/null || true)"
fi

prev_workspace=""
prev_window_count="0"
prev_orientation=""
prev_prefer_first="0"
if [ -f "$RUNTIME_STATE_FILE" ]; then
  IFS=$'\t' read -r _prev_id prev_workspace prev_window_count prev_orientation prev_prefer_first < "$RUNTIME_STATE_FILE" || true
fi
[[ "$prev_window_count" =~ ^[0-9]+$ ]] || prev_window_count=0

# Avoid redundant split commands while focus stays on the same window.
if [ "$last_focused_window_id" = "$focused_window_id" ]; then
  exit 0
fi
printf '%s\n' "$focused_window_id" > "$STATE_FILE"

# Hypr dwindle side approximation: on new window creation, place new window
# on the "first" side (left/top) if cursor was in that half previously.
if [ "$prev_workspace" = "$focused_workspace" ] && [ "$window_count" -gt "$prev_window_count" ] && [ "$prev_prefer_first" = "1" ]; then
  if [ "$prev_orientation" = "horizontal" ]; then
    "$AERO_BIN" move --window-id "$focused_window_id" left >/dev/null 2>&1 || true
  elif [ "$prev_orientation" = "vertical" ]; then
    "$AERO_BIN" move --window-id "$focused_window_id" up >/dev/null 2>&1 || true
  fi
fi

size_csv="$(
  osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  set frontProc to first process whose frontmost is true
  if (count of windows of frontProc) is 0 then return ""
  set focusedWin to value of attribute "AXFocusedWindow" of frontProc
  if focusedWin is missing value then return ""
  tell focusedWin
    set p to position
    set s to size
    return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
  end tell
end tell
APPLESCRIPT
)"

mouse_csv="$(
  osascript -l JavaScript <<'JXA' 2>&1 || true
ObjC.import('AppKit');
const p = $.NSEvent.mouseLocation;
const screens = $.NSScreen.screens;
let maxH = 0;
for (let i = 0; i < screens.count; i++) {
  const s = screens.objectAtIndex(i).frame;
  if (s.size.height > maxH) maxH = s.size.height;
}
console.log(`${Math.trunc(p.x)},${Math.trunc(p.y)},${Math.trunc(maxH)}`);
JXA
)"

window_x="$(printf '%s' "$size_csv" | awk -F',' '{gsub(/[^0-9]/, "", $1); print $1}')"
window_y="$(printf '%s' "$size_csv" | awk -F',' '{gsub(/[^0-9]/, "", $2); print $2}')"
window_width="$(printf '%s' "$size_csv" | awk -F',' '{gsub(/[^0-9]/, "", $3); print $3}')"
window_height="$(printf '%s' "$size_csv" | awk -F',' '{gsub(/[^0-9]/, "", $4); print $4}')"
mouse_x="$(printf '%s' "$mouse_csv" | awk -F',' '{gsub(/[^0-9]/, "", $1); print $1}')"
mouse_y_bottom="$(printf '%s' "$mouse_csv" | awk -F',' '{gsub(/[^0-9]/, "", $2); print $2}')"
screen_height="$(printf '%s' "$mouse_csv" | awk -F',' '{gsub(/[^0-9]/, "", $3); print $3}')"

mouse_y_top=""
if [[ "$screen_height" =~ ^[0-9]+$ ]] && [[ "$mouse_y_bottom" =~ ^[0-9]+$ ]]; then
  mouse_y_top=$((screen_height - mouse_y_bottom))
fi

orientation="vertical"
if [[ "$window_width" =~ ^[0-9]+$ ]] && [[ "$window_height" =~ ^[0-9]+$ ]] && \
  awk "BEGIN { exit !($window_width > ($window_height * $SPLIT_WIDTH_MULTIPLIER)) }"; then
  orientation="horizontal"
fi

prefer_first=0
if [[ "$window_x" =~ ^[0-9]+$ ]] && [[ "$window_y" =~ ^[0-9]+$ ]] && [[ "$window_width" =~ ^[0-9]+$ ]] && [[ "$window_height" =~ ^[0-9]+$ ]] && \
   [[ "$mouse_x" =~ ^[0-9]+$ ]] && [[ "$mouse_y_top" =~ ^[0-9]+$ ]]; then
  if [ "$mouse_x" -ge "$window_x" ] && [ "$mouse_x" -le $((window_x + window_width)) ] && \
     [ "$mouse_y_top" -ge "$window_y" ] && [ "$mouse_y_top" -le $((window_y + window_height)) ]; then
    rel_x=$((mouse_x - window_x))
    rel_y=$((mouse_y_top - window_y))
    if [ "$orientation" = "horizontal" ] && [ "$rel_x" -lt $((window_width / 2)) ]; then
      prefer_first=1
    elif [ "$orientation" = "vertical" ] && [ "$rel_y" -lt $((window_height / 2)) ]; then
      prefer_first=1
    fi
  fi
fi

# Hyprland dwindle auto split approximation:
# orientation by focused container ratio.
if [ "$orientation" = "horizontal" ]; then
  printf 'horizontal\n' > "$ORIENTATION_FILE"
  printf '%s\n' "$([ "$prefer_first" = "1" ] && echo left || echo right)" > "$SIDE_FILE"
  "$AERO_BIN" split --window-id "$focused_window_id" horizontal >/dev/null 2>&1 || true
else
  printf 'vertical\n' > "$ORIENTATION_FILE"
  printf '%s\n' "$([ "$prefer_first" = "1" ] && echo top || echo bottom)" > "$SIDE_FILE"
  "$AERO_BIN" split --window-id "$focused_window_id" vertical >/dev/null 2>&1 || true
fi

printf '%s\t%s\t%s\t%s\t%s\n' \
  "$focused_window_id" \
  "$focused_workspace" \
  "$window_count" \
  "$orientation" \
  "$prefer_first" > "$RUNTIME_STATE_FILE"
