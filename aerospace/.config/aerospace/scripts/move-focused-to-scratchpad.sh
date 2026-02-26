#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
SCRATCH_WORKSPACE="${AEROSPACE_SCRATCH_WORKSPACE:-S}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

focused_window_id="$($AERO_BIN list-windows --focused --format '%{window-id}' 2>/dev/null || true)"
[ -n "$focused_window_id" ] || exit 0

"$AERO_BIN" move-node-to-workspace --window-id "$focused_window_id" "$SCRATCH_WORKSPACE" >/dev/null 2>&1 || true
