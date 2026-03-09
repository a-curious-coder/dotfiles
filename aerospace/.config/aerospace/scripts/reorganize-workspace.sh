#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
STAMP_FILE="$STATE_DIR/reorganize-last-run"
ARRANGER_SCRIPT="${AEROSPACE_ARRANGER_SCRIPT:-$HOME/.config/aerospace/scripts/auto-split-orientation.sh}"

mkdir -p "$STATE_DIR"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STAMP_FILE"

if [ ! -x "$ARRANGER_SCRIPT" ]; then
  exit 0
fi

"$ARRANGER_SCRIPT" --repair focused >/dev/null 2>&1 || true
