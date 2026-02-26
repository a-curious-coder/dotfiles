#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
STAMP_FILE="$STATE_DIR/reorganize-last-run"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$STATE_DIR"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STAMP_FILE"

"$AERO_BIN" flatten-workspace-tree >/dev/null 2>&1 || true
"$AERO_BIN" balance-sizes >/dev/null 2>&1 || true
