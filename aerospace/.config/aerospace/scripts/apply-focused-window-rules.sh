#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

focused_window_id="$($AERO_BIN list-windows --focused --format '%{window-id}' 2>/dev/null || true)"
app_id="$($AERO_BIN list-windows --focused --format '%{app-bundle-id}' 2>/dev/null || true)"
window_title="$($AERO_BIN list-windows --focused --format '%{window-title}' 2>/dev/null || true)"

[ -n "$focused_window_id" ] || exit 0

should_float=0
center_window=0
width_pct=0
height_pct=0
position_x_pct=""
position_y_pct=""

title_lc="$(printf '%s' "$window_title" | tr '[:upper:]' '[:lower:]')"

# App-level floating approximations for settings/viewer utilities.
case "$app_id" in
  com.apple.systempreferences|com.apple.ActivityMonitor|com.apple.print.PrintCenter)
    should_float=1
    center_window=1
    width_pct=70
    height_pct=70
    ;;
  com.apple.Preview)
    should_float=1
    center_window=1
    width_pct=72
    height_pct=72
    ;;
esac

# Dialog-like rules.
if printf '%s' "$title_lc" | grep -Eq '^authentication required$'; then
  should_float=1
  center_window=1
  width_pct=50
  height_pct=34
elif printf '%s' "$title_lc" | grep -Eq '^save as$|^add folder to workspace$'; then
  should_float=1
  center_window=1
  width_pct=70
  height_pct=60
elif printf '%s' "$title_lc" | grep -Eq 'open files'; then
  should_float=1
  center_window=1
  width_pct=70
  height_pct=60
fi

# Steam/Heroic popup approximation.
if [ "$app_id" = 'com.valvesoftware.steam' ] && [ "$window_title" != 'Steam' ]; then
  should_float=1
fi
if [ "$app_id" = 'com.heroicgameslauncher.hgl' ] && [ "$window_title" != 'Heroic Games Launcher' ]; then
  should_float=1
fi

# Picture-in-picture approximation (pin/top-level is not available in AeroSpace).
if printf '%s' "$title_lc" | grep -Eq '^picture-in-picture$'; then
  should_float=1
  width_pct=28
  height_pct=24
  position_x_pct=71
  position_y_pct=7
fi

if [ "$should_float" -ne 1 ]; then
  exit 0
fi

"$AERO_BIN" layout --window-id "$focused_window_id" floating >/dev/null 2>&1 || true
"$AERO_BIN" focus --window-id "$focused_window_id" >/dev/null 2>&1 || true

if [ "$width_pct" -le 0 ] || [ "$height_pct" -le 0 ]; then
  exit 0
fi

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

left="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $1); print $1}')"
top="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $2); print $2}')"
right="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $3); print $3}')"
bottom="$(printf '%s' "$bounds_csv" | awk -F',' '{gsub(/[^0-9-]/, "", $4); print $4}')"

if ! [[ "$left" =~ ^-?[0-9]+$ && "$top" =~ ^-?[0-9]+$ && "$right" =~ ^-?[0-9]+$ && "$bottom" =~ ^-?[0-9]+$ ]]; then
  exit 0
fi

screen_w=$((right - left))
screen_h=$((bottom - top))
[ "$screen_w" -gt 0 ] || exit 0
[ "$screen_h" -gt 0 ] || exit 0

target_w=$((screen_w * width_pct / 100))
target_h=$((screen_h * height_pct / 100))

if [ "$center_window" -eq 1 ]; then
  target_x=$((left + (screen_w - target_w) / 2))
  target_y=$((top + (screen_h - target_h) / 2))
else
  px="${position_x_pct:-50}"
  py="${position_y_pct:-50}"
  target_x=$((left + (screen_w * px / 100)))
  target_y=$((top + (screen_h * py / 100)))
fi

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
