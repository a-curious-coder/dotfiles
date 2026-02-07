#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
DIRECTION="${1:-next}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 1
fi

FOCUSED_APP="$($AERO_BIN list-windows --focused --format '%{app-bundle-id}' 2>/dev/null || true)"
if [ -z "$FOCUSED_APP" ]; then
  exit 0
fi

WINDOWS=()
while IFS= read -r line; do
  [ -z "$line" ] && continue
  WINDOWS+=("$line")
done < <($AERO_BIN list-windows --workspace focused --app-bundle-id "$FOCUSED_APP" --format '%{window-id}' 2>/dev/null)

COUNT=${#WINDOWS[@]}
if [ "$COUNT" -le 1 ]; then
  exit 0
fi

FOCUSED_ID="$($AERO_BIN list-windows --focused --format '%{window-id}' 2>/dev/null || true)"
NEXT_ID=""
for i in "${!WINDOWS[@]}"; do
  if [ "${WINDOWS[$i]}" = "$FOCUSED_ID" ]; then
    if [ "$DIRECTION" = "prev" ]; then
      NEXT_INDEX=$(( (i - 1 + COUNT) % COUNT ))
    else
      NEXT_INDEX=$(( (i + 1) % COUNT ))
    fi
    NEXT_ID="${WINDOWS[$NEXT_INDEX]}"
    break
  fi
done

if [ -n "$NEXT_ID" ]; then
  $AERO_BIN focus --window-id "$NEXT_ID" >/dev/null 2>&1
fi
