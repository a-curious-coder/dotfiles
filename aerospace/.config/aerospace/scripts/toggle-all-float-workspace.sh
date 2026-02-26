#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
STATE_FILE="$STATE_DIR/workspace-layout-mode.tsv"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$STATE_DIR"

workspace="$($AERO_BIN list-workspaces --focused --format '%{workspace}' 2>/dev/null || true)"
[ -n "$workspace" ] || exit 0

current_mode="tiling"
if [ -f "$STATE_FILE" ]; then
  existing_mode="$(awk -F'\t' -v ws="$workspace" '$1==ws {print $2}' "$STATE_FILE" 2>/dev/null | tail -n1 || true)"
  if [ "$existing_mode" = "floating" ]; then
    current_mode="floating"
  fi
fi

if [ "$current_mode" = "floating" ]; then
  target_mode="tiling"
else
  target_mode="floating"
fi

while IFS= read -r window_id; do
  [ -n "$window_id" ] || continue
  "$AERO_BIN" layout --window-id "$window_id" "$target_mode" >/dev/null 2>&1 || true
done < <("$AERO_BIN" list-windows --workspace "$workspace" --format '%{window-id}' 2>/dev/null)

if [ -f "$STATE_FILE" ]; then
  awk -F'\t' -v ws="$workspace" '$1!=ws {print $0}' "$STATE_FILE" > "${STATE_FILE}.tmp" || true
else
  : > "${STATE_FILE}.tmp"
fi
printf '%s\t%s\n' "$workspace" "$target_mode" >> "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"
