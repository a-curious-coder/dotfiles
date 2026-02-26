#!/usr/bin/env sh

if [ -z "${AEROSPACE_BIN:-}" ]; then
  if command -v aerospace >/dev/null 2>&1; then
    AEROSPACE_BIN="aerospace"
  elif [ -x "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]; then
    AEROSPACE_BIN="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  fi
fi

if [ -z "${AEROSPACE_BIN:-}" ]; then
  sketchybar --set "${NAME:-windowlist}" drawing=off >/dev/null 2>&1 || true
  exit 0
fi

focused_workspace="$($AEROSPACE_BIN list-workspaces --focused --format '%{workspace}' 2>/dev/null || true)"
focused_window_id="$($AEROSPACE_BIN list-windows --focused --format '%{window-id}' 2>/dev/null || true)"

if [ -z "$focused_workspace" ]; then
  sketchybar --set "${NAME:-windowlist}" drawing=off >/dev/null 2>&1 || true
  exit 0
fi

label=""

while IFS=$'\t' read -r window_id app_name window_title; do
  [ -n "$window_id" ] || continue

  short_name="$app_name"
  if [ -z "$short_name" ]; then
    short_name="$window_title"
  fi

  short_name="$(printf '%s' "$short_name" | tr -s ' ' | sed 's/^ //; s/ $//')"
  if [ "$(printf '%s' "$short_name" | wc -m | tr -d ' ')" -gt 18 ]; then
    short_name="$(printf '%s' "$short_name" | cut -c1-15)..."
  fi

  if [ "$window_id" = "$focused_window_id" ]; then
    token="[$short_name]"
  else
    token="$short_name"
  fi

  if [ -z "$label" ]; then
    label="$token"
  else
    label="$label  ·  $token"
  fi
done <<EOF_WINDOWS
$($AEROSPACE_BIN list-windows --workspace "$focused_workspace" --format '%{window-id}%{tab}%{app-name}%{tab}%{window-title}' 2>/dev/null)
EOF_WINDOWS

if [ -z "$label" ]; then
  sketchybar --set "${NAME:-windowlist}" drawing=off >/dev/null 2>&1 || true
  exit 0
fi

prefix="WS $focused_workspace"
sketchybar --set "${NAME:-windowlist}" drawing=on label="$prefix  $label" >/dev/null 2>&1 || true
