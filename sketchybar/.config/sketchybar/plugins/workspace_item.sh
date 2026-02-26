#!/usr/bin/env sh

if [ -z "${AEROSPACE_BIN:-}" ]; then
  if command -v aerospace >/dev/null 2>&1; then
    AEROSPACE_BIN="aerospace"
  elif [ -x "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]; then
    AEROSPACE_BIN="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  fi
fi

if [ -z "${AEROSPACE_BIN:-}" ]; then
  exit 0
fi

case "$NAME" in
  workspace.*) workspace="${NAME#workspace.}" ;;
  *) exit 0 ;;
esac

if [ "$SENDER" = "mouse.clicked" ]; then
  "$AEROSPACE_BIN" workspace "$workspace" >/dev/null 2>&1 || true
elif [ "$SENDER" = "mouse.scrolled" ]; then
  delta="${SCROLL_DELTA:-0}"
  case "$delta" in
    ''|*[!0-9-]*) delta=0 ;;
  esac

  if [ "$delta" -gt 0 ]; then
    "$AEROSPACE_BIN" workspace --wrap-around prev >/dev/null 2>&1 || true
  elif [ "$delta" -lt 0 ]; then
    "$AEROSPACE_BIN" workspace --wrap-around next >/dev/null 2>&1 || true
  fi
fi

"$CONFIG_DIR/plugins/workspaces.sh" >/dev/null 2>&1 || true
