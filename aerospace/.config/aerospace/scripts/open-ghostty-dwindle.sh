#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
MARKER_PREFIX="$STATE_DIR/hypr-dwindle-presplit-"
WATCHER_START_SCRIPT="${AEROSPACE_WATCHER_START_SCRIPT:-$HOME/.config/aerospace/scripts/start-auto-split-watcher.sh}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exec open -na Ghostty
fi

mkdir -p "$STATE_DIR"

if [ -x "$WATCHER_START_SCRIPT" ]; then
  "$WATCHER_START_SCRIPT" < /dev/null >/dev/null 2>&1 || true
fi

workspace_key() {
  printf '%s' "$1" | tr -cs '[:alnum:]._-' '_'
}

model_file() {
  printf '%s/hypr-dwindle-model-%s.tsv\n' "$STATE_DIR" "$(workspace_key "$1")"
}

marker_file() {
  printf '%s%s\n' "$MARKER_PREFIX" "$(workspace_key "$1")"
}

layout_for_anchor_path() {
  local path="${1:-}"
  if [ -z "$path" ]; then
    printf 'horizontal'
    return
  fi

  case "${path##*/}" in
    L|R) printf 'vertical' ;;
    U|D) printf 'horizontal' ;;
    *) printf 'horizontal' ;;
  esac
}

contains_id() {
  local ids="${1:-}"
  local target="${2:-}"
  case $'\n'"$ids"$'\n' in
    *$'\n'"$target"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

list_ghostty_ids() {
  "$AERO_BIN" list-windows --all --format '%{window-id}%{tab}%{app-name}' < /dev/null 2>/dev/null | awk -F'\t' '$2 == "Ghostty" { print $1 }'
}

focused_line="$("$AERO_BIN" list-windows --focused --format '%{window-id}%{tab}%{workspace}' < /dev/null 2>/dev/null || true)"
IFS=$'\t' read -r focused_window_id focused_workspace <<< "$focused_line"
before_ids="$(list_ghostty_ids || true)"

if [ -n "${focused_window_id:-}" ] && [ -n "${focused_workspace:-}" ]; then
  desired_layout='horizontal'
  focused_model_path="$(awk -F'\t' -v wid="$focused_window_id" '$1 == wid { print $2; exit }' "$(model_file "$focused_workspace")" 2>/dev/null || true)"
  if [ -n "$focused_model_path" ]; then
    desired_layout="$(layout_for_anchor_path "$focused_model_path")"
  fi

  "$AERO_BIN" focus --window-id "$focused_window_id" < /dev/null >/dev/null 2>&1 || true
  "$AERO_BIN" split --window-id "$focused_window_id" "$desired_layout" < /dev/null >/dev/null 2>&1 || true
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$(marker_file "$focused_workspace")"
fi

open -na Ghostty

if [ -n "${focused_workspace:-}" ]; then
  attempt=0
  while [ "$attempt" -lt 40 ]; do
    current_ids="$(list_ghostty_ids || true)"
    while IFS= read -r ghostty_window_id; do
      [ -n "$ghostty_window_id" ] || continue
      if ! contains_id "$before_ids" "$ghostty_window_id"; then
        "$AERO_BIN" move-node-to-workspace --window-id "$ghostty_window_id" "$focused_workspace" < /dev/null >/dev/null 2>&1 || true
        "$AERO_BIN" focus --window-id "$ghostty_window_id" < /dev/null >/dev/null 2>&1 || true
        exit 0
      fi
    done <<< "$current_ids"
    attempt=$((attempt + 1))
    sleep 0.05
  done
fi
