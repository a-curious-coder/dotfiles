#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-$(command -v yabai || true)}"
if [[ -z "$YABAI_BIN" ]]; then
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

target_spaces=9
space_count="$($YABAI_BIN -m query --spaces 2>/dev/null | jq 'length' 2>/dev/null || echo 0)"

if [[ "$space_count" =~ ^[0-9]+$ ]]; then
  while (( space_count < target_spaces )); do
    $YABAI_BIN -m space --create >/dev/null 2>&1 || break
    space_count=$((space_count + 1))
  done
fi

for idx in $(seq 1 "$target_spaces"); do
  $YABAI_BIN -m space "$idx" --label "$idx" >/dev/null 2>&1 || true
done
