#!/usr/bin/env sh

APP="$INFO"
if [ -z "$APP" ]; then
  APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)"
fi

if [ -n "$APP" ]; then
  sketchybar --set "$NAME" label="$APP"
fi
