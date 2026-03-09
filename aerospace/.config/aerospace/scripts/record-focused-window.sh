#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
SUPPRESS_DIR="$STATE_DIR/hypr-dwindle-callback-suppress"
MAX_HISTORY="${AEROSPACE_DWINDLE_HISTORY_LIMIT:-12}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$STATE_DIR"

if [ -d "$SUPPRESS_DIR" ]; then
  suppress_pid="$(cat "$SUPPRESS_DIR/pid" 2>/dev/null || true)"
  if [[ "$suppress_pid" =~ ^[0-9]+$ ]] && kill -0 "$suppress_pid" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$SUPPRESS_DIR" >/dev/null 2>&1 || true
fi

workspace_key() {
  printf '%s' "$1" | tr -cs '[:alnum:]._-' '_'
}

history_file() {
  printf '%s/hypr-dwindle-focus-history-%s.tsv\n' "$STATE_DIR" "$(workspace_key "$1")"
}

ids_blob() {
  local input="${1:-}"
  printf '%s\n' "$input" | awk 'NF { printf "|%s", $0 } END { print "|" }'
}

focused_line="$("$AERO_BIN" list-windows --focused --format '%{window-id}%{tab}%{workspace}%{tab}%{window-is-fullscreen}' < /dev/null 2>/dev/null || true)"
[ -n "$focused_line" ] || exit 0

IFS=$'\t' read -r focused_window_id focused_workspace focused_fullscreen <<< "$focused_line"
[ -n "${focused_window_id:-}" ] || exit 0
[ -n "${focused_workspace:-}" ] || exit 0

if [ "${focused_fullscreen:-false}" = 'true' ]; then
  exit 0
fi

live_ids="$("$AERO_BIN" list-windows --workspace "$focused_workspace" --format '%{window-id}' < /dev/null 2>/dev/null | awk 'NF' || true)"
[ -n "$live_ids" ] || exit 0
live_blob="$(ids_blob "$live_ids")"

history_path="$(history_file "$focused_workspace")"
{
  printf '%s\n' "$focused_window_id"
  if [ -f "$history_path" ]; then
    cat "$history_path"
  fi
} | awk -v live="$live_blob" -v current="$focused_window_id" -v limit="$MAX_HISTORY" '
  function contains(list, value) {
    return index(list, "|" value "|") > 0
  }
  NF && contains(live, $1) && !seen[$1] {
    print $1
    seen[$1] = 1
    count++
    if (count >= limit) {
      exit
    }
  }
' > "${history_path}.tmp"

mv "${history_path}.tmp" "$history_path"
