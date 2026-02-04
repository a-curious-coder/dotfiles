#!/usr/bin/env sh

PERCENTAGE="$(pmset -g batt 2>/dev/null | grep -Eo "[0-9]+%" | head -n1 | tr -d '%')"
CHARGING="$(pmset -g batt 2>/dev/null | grep -q 'AC Power' && echo yes || true)"

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" drawing=on

LABEL="${PERCENTAGE}%"
COLOR="${SB_COLOR_FG_BRIGHT:-0xfffffcf0}"

if [ -n "$CHARGING" ]; then
  LABEL="${PERCENTAGE}%+"
  COLOR="${SB_COLOR_GREEN:-$COLOR}"
elif [ "$PERCENTAGE" -le 20 ]; then
  COLOR="${SB_COLOR_RED:-$COLOR}"
fi

sketchybar --set "$NAME" label="$LABEL" label.color="$COLOR"
