#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-$(command -v yabai || true)}"
DIRECTION="${1:-next}"

if [[ -z "$YABAI_BIN" ]] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

focused_json="$($YABAI_BIN -m query --windows --window 2>/dev/null || true)"
if [[ -z "$focused_json" ]] || [[ "$focused_json" == "null" ]]; then
  exit 0
fi

focused_id="$(jq -r '.id // empty' <<<"$focused_json")"
focused_app="$(jq -r '.app // empty' <<<"$focused_json")"
focused_space="$(jq -r '.space // empty' <<<"$focused_json")"

if [[ -z "$focused_id" || -z "$focused_app" || -z "$focused_space" ]]; then
  exit 0
fi

mapfile -t window_ids < <(
  $YABAI_BIN -m query --windows --space "$focused_space" 2>/dev/null |
    jq -r --arg app "$focused_app" '.[] | select(.app == $app and ."is-minimized" == false) | .id' |
    sort -n
)

count="${#window_ids[@]}"
if (( count <= 1 )); then
  exit 0
fi

current_index=-1
for i in "${!window_ids[@]}"; do
  if [[ "${window_ids[$i]}" == "$focused_id" ]]; then
    current_index="$i"
    break
  fi
done

if (( current_index < 0 )); then
  exit 0
fi

if [[ "$DIRECTION" == "prev" ]]; then
  next_index=$(( (current_index - 1 + count) % count ))
else
  next_index=$(( (current_index + 1) % count ))
fi

next_id="${window_ids[$next_index]}"
if [[ -n "$next_id" ]]; then
  $YABAI_BIN -m window --focus "$next_id" >/dev/null 2>&1 || true
fi
