#!/usr/bin/env bash
set -u

HIGHLIGHT="${SB_COLOR_FG_BRIGHT:-0xfffffcf0}"
NORMAL="${SB_COLOR_FG:-0xffcecdc3}"
DIM="${SB_COLOR_DIM:-0xff6f6e69}"
WORKSPACES="${WM_WORKSPACES:-1 2 3 4 5 6 7 8 9}"

set_item() {
  sketchybar --set "$@" >/dev/null 2>&1 || true
}

backend="${WM_BACKEND:-}"
if [ -z "$backend" ]; then
  if command -v yabai >/dev/null 2>&1; then
    backend="yabai"
  elif command -v aerospace >/dev/null 2>&1 || [ -x "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]; then
    backend="aerospace"
  else
    exit 0
  fi
fi

if [ "$backend" = "aerospace" ]; then
  if [ -z "${AEROSPACE_BIN:-}" ]; then
    if command -v aerospace >/dev/null 2>&1; then
      AEROSPACE_BIN="aerospace"
    elif [ -x "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]; then
      AEROSPACE_BIN="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
    else
      exit 0
    fi
  fi

  sleep 0.15

  WORKSPACES_INFO="$($AEROSPACE_BIN list-workspaces --all --format '%{workspace} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-focused} %{workspace-is-visible}' 2>/dev/null)"
  MONITORS_INFO="$($AEROSPACE_BIN list-monitors --format '%{monitor-id} %{monitor-appkit-nsscreen-screens-id}' 2>/dev/null)"

  DESIRED_LIST="$(printf '%s\n' "$MONITORS_INFO" | while read -r mid display_id; do
    [ -n "$mid" ] || continue
    active_ws="$($AEROSPACE_BIN list-workspaces --monitor "$mid" --empty no --format '%{workspace}' 2>/dev/null </dev/null)"
    visible_ws="$(printf '%s\n' "$WORKSPACES_INFO" | awk -v d="$display_id" '$2==d && $4=="true" {print $1}')"
    for ws in $active_ws $visible_ws; do
      [ -n "$ws" ] || continue
      printf '%s %s\n' "$ws" "$display_id"
    done
  done | awk 'NF{key=$1" "$2; if(!seen[key]++){print}}')"

  STATE_HASH="$(printf '%s\n%s\n%s\n' "$WORKSPACES_INFO" "$MONITORS_INFO" "$DESIRED_LIST" | cksum | awk '{print $1}')"
  STATE_FILE="${TMPDIR:-/tmp}/sketchybar-workspaces-aerospace.state"
  if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$STATE_HASH" ]; then
    exit 0
  fi
  printf '%s' "$STATE_HASH" > "$STATE_FILE"

  printf '%s\n' "$WORKSPACES_INFO" | while read -r ws display_id _focused _visible; do
    [ -n "$ws" ] || continue
    if ! printf '%s\n' "$DESIRED_LIST" | grep -q "^${ws} ${display_id}$"; then
      set_item "workspace.${ws}" drawing=off
    fi
  done

  printf '%s\n' "$DESIRED_LIST" | while read -r ws display_id; do
    [ -n "$ws" ] || continue
    set_item "workspace.${ws}" drawing=on display="${display_id}"
  done

  printf '%s\n' "$WORKSPACES_INFO" | while read -r ws _display_id _focused visible; do
    [ -n "$ws" ] || continue
    if [ "$visible" = "true" ]; then
      color="$HIGHLIGHT"
    else
      color="$DIM"
    fi
    set_item "workspace.${ws}" label.color="${color}"
  done
  exit 0
fi

if [ "$backend" = "yabai" ]; then
  if ! command -v jq >/dev/null 2>&1; then
    exit 0
  fi
  YABAI_BIN="${YABAI_BIN:-$(command -v yabai || true)}"
  if [ -z "$YABAI_BIN" ]; then
    exit 0
  fi

  sleep 0.08

  SPACES_JSON="$($YABAI_BIN -m query --spaces 2>/dev/null || echo '[]')"
  DISPLAYS_JSON="$($YABAI_BIN -m query --displays 2>/dev/null || echo '[]')"

  SPACE_INFO_LINES="$(jq -r '.[] | "\(.index) \(.display) \(."has-focus") \(."is-visible") \(.windows|length)"' <<<"$SPACES_JSON" 2>/dev/null || true)"
  if [ -z "$SPACE_INFO_LINES" ]; then
    for ws in $WORKSPACES; do
      set_item "workspace.${ws}" drawing=on
      set_item "workspace.${ws}" label.color="${DIM}"
    done
    exit 0
  fi

  DESIRED_LIST="$(printf '%s\n' "$SPACE_INFO_LINES" | awk '$4=="true" || $5>0 || $3=="true" {print $1" "$2}' | awk '!seen[$0]++')"

  if [ -z "$DESIRED_LIST" ]; then
    DESIRED_LIST="$(printf '%s\n' "$SPACE_INFO_LINES" | awk '$3=="true" {print $1" "$2}' | awk '!seen[$0]++')"
  fi

  STATE_HASH="$(printf '%s\n%s\n%s\n%s\n' "$SPACES_JSON" "$DISPLAYS_JSON" "$DESIRED_LIST" "$WORKSPACES" | cksum | awk '{print $1}')"
  STATE_FILE="${TMPDIR:-/tmp}/sketchybar-workspaces-yabai.state"
  if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$STATE_HASH" ]; then
    exit 0
  fi
  printf '%s' "$STATE_HASH" > "$STATE_FILE"

  for ws in $WORKSPACES; do
    set_item "workspace.${ws}" drawing=off
    set_item "workspace.${ws}" label.color="${NORMAL}"
  done

  printf '%s\n' "$DESIRED_LIST" | while read -r ws display_id; do
    [ -n "$ws" ] || continue
    set_item "workspace.${ws}" drawing=on display="${display_id}"
  done

  printf '%s\n' "$SPACE_INFO_LINES" | while read -r ws _display_id _focused visible _window_count; do
    [ -n "$ws" ] || continue
    if [ "$visible" = "true" ]; then
      color="$HIGHLIGHT"
    else
      color="$DIM"
    fi
    set_item "workspace.${ws}" label.color="${color}"
  done
  exit 0
fi

exit 0
