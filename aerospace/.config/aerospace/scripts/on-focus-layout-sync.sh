#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
SUPPRESS_DIR="$STATE_DIR/hypr-dwindle-callback-suppress"
FOCUS_SCRIPT="${AEROSPACE_FOCUS_TRACKER_SCRIPT:-$HOME/.config/aerospace/scripts/record-focused-window.sh}"
WATCHER_START_SCRIPT="${AEROSPACE_WATCHER_START_SCRIPT:-$HOME/.config/aerospace/scripts/start-auto-split-watcher.sh}"

mkdir -p "$STATE_DIR"

if [ -d "$SUPPRESS_DIR" ]; then
  suppress_pid="$(cat "$SUPPRESS_DIR/pid" 2>/dev/null || true)"
  if [[ "$suppress_pid" =~ ^[0-9]+$ ]] && kill -0 "$suppress_pid" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$SUPPRESS_DIR" >/dev/null 2>&1 || true
fi

if [ -x "$WATCHER_START_SCRIPT" ]; then
  "$WATCHER_START_SCRIPT" < /dev/null >/dev/null 2>&1 || true
fi

if [ -x "$FOCUS_SCRIPT" ]; then
  "$FOCUS_SCRIPT" < /dev/null >/dev/null 2>&1 || true
fi
