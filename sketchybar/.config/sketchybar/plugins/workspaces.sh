#!/usr/bin/env sh

if [ -z "${AEROSPACE_BIN:-}" ]; then
  if command -v aerospace >/dev/null 2>&1; then
    AEROSPACE_BIN="aerospace"
  elif [ -x "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]; then
    AEROSPACE_BIN="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  fi
fi
if [ -z "${AEROSPACE_BIN:-}" ]; then
  exit 0
fi

HIGHLIGHT="${SB_COLOR_FG_BRIGHT:-0xfffffcf0}"
NORMAL="${SB_COLOR_FG:-0xffcecdc3}"
DIM="${SB_COLOR_DIM:-0xff6f6e69}"

# Let AeroSpace settle on workspace changes.
sleep 0.15

WORKSPACES_INFO="$("$AEROSPACE_BIN" list-workspaces --all --format '%{workspace} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-focused} %{workspace-is-visible}' 2>/dev/null)"
MONITORS_INFO="$("$AEROSPACE_BIN" list-monitors --format '%{monitor-id} %{monitor-appkit-nsscreen-screens-id}' 2>/dev/null)"

# Build desired (workspace, display) pairs: non-empty + visible.
DESIRED_LIST="$(printf '%s\n' "$MONITORS_INFO" | while read -r mid display_id; do
  [ -n "$mid" ] || continue
  active_ws="$("$AEROSPACE_BIN" list-workspaces --monitor "$mid" --empty no --format '%{workspace}' 2>/dev/null </dev/null)"
  visible_ws="$(printf '%s\n' "$WORKSPACES_INFO" | awk -v d="$display_id" '$2==d && $4=="true" {print $1}')"
  for ws in $active_ws $visible_ws; do
    [ -n "$ws" ] || continue
    printf '%s %s\n' "$ws" "$display_id"
  done
done | awk 'NF{key=$1" "$2; if(!seen[key]++){print}}')"

STATE_HASH="$(printf '%s\n%s\n%s\n' "$WORKSPACES_INFO" "$MONITORS_INFO" "$DESIRED_LIST" | cksum | awk '{print $1}')"
STATE_FILE="${TMPDIR:-/tmp}/sketchybar-workspaces.state"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$STATE_HASH" ]; then
  exit 0
fi
printf '%s' "$STATE_HASH" > "$STATE_FILE"

# Hide only workspaces that are not desired for their display.
printf '%s\n' "$WORKSPACES_INFO" | while read -r ws display_id _focused _visible; do
  [ -n "$ws" ] || continue
  if ! printf '%s\n' "$DESIRED_LIST" | grep -q "^${ws} ${display_id}$"; then
    sketchybar --set "workspace.${ws}" drawing=off label="$ws"
  fi
done

# Show desired workspaces on their display.
printf '%s\n' "$DESIRED_LIST" | while read -r ws display_id; do
  [ -n "$ws" ] || continue
  sketchybar --set "workspace.${ws}" drawing=on display="$display_id" label="$ws"
done

# Highlight visible workspace(s) per display; dim others.
printf '%s\n' "$WORKSPACES_INFO" | while read -r ws _display_id _focused visible; do
  [ -n "$ws" ] || continue
  if [ "$visible" = "true" ]; then
    color="$HIGHLIGHT"
  else
    color="$DIM"
  fi
  sketchybar --set "workspace.${ws}" label="$ws" label.color="$color"
done
