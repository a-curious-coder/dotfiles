#!/usr/bin/env sh

day="$(date '+%d' | sed 's/^0//')"
case "$day" in
  11|12|13) suffix="th" ;;
  *1) suffix="st" ;;
  *2) suffix="nd" ;;
  *3) suffix="rd" ;;
  *) suffix="th" ;;
esac

dow="$(date '+%A')"
month="$(date '+%B')"
time="$(date '+%H:%M')"

sketchybar --set "$NAME" label="${dow} ${day}${suffix} ${month} ${time}"
