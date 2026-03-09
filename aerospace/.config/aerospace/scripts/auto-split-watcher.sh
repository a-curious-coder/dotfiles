#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
LOCK_DIR="$STATE_DIR/auto-split-watcher-lock"
ARRANGER_SCRIPT="${AEROSPACE_ARRANGER_SCRIPT:-$HOME/.config/aerospace/scripts/auto-split-orientation.sh}"
FOCUS_SCRIPT="${AEROSPACE_FOCUS_TRACKER_SCRIPT:-$HOME/.config/aerospace/scripts/record-focused-window.sh}"
INTERVAL="${AEROSPACE_AUTO_SPLIT_WATCH_INTERVAL:-0.08}"

mkdir -p "$STATE_DIR"

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  local stale_pid=""
  stale_pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [[ "$stale_pid" =~ ^[0-9]+$ ]] && kill -0 "$stale_pid" 2>/dev/null; then
    return 1
  fi

  rm -rf "$LOCK_DIR" >/dev/null 2>&1 || true
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  return 1
}

if ! acquire_lock; then
  exit 0
fi

cleanup() {
  rm -rf "$LOCK_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

if command -v "$AERO_BIN" >/dev/null 2>&1 && [ -x "$FOCUS_SCRIPT" ]; then
  "$FOCUS_SCRIPT" < /dev/null >/dev/null 2>&1 || true
fi

while true; do
  if command -v "$AERO_BIN" >/dev/null 2>&1 && [ -x "$ARRANGER_SCRIPT" ]; then
    "$ARRANGER_SCRIPT" < /dev/null >/dev/null 2>&1 || true
  fi
  sleep "$INTERVAL"
done
