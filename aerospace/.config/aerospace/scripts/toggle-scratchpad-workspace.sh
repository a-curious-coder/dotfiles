#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
SCRATCH_WORKSPACE="${AEROSPACE_SCRATCH_WORKSPACE:-S}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

focused_workspace="$($AERO_BIN list-workspaces --focused --format '%{workspace}' 2>/dev/null || true)"
[ -n "$focused_workspace" ] || exit 0

if [ "$focused_workspace" = "$SCRATCH_WORKSPACE" ]; then
  "$AERO_BIN" workspace-back-and-forth >/dev/null 2>&1 || \
    "$AERO_BIN" workspace --wrap-around prev >/dev/null 2>&1 || true
  exit 0
fi

"$AERO_BIN" summon-workspace "$SCRATCH_WORKSPACE" >/dev/null 2>&1 || true
"$AERO_BIN" workspace "$SCRATCH_WORKSPACE" >/dev/null 2>&1 || true
