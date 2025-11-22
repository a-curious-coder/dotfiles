#!/bin/bash

MONITOR_1="DP-1"
MONITOR_2="HDMI-A-1"

CURRENT_MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

if [ "$CURRENT_MONITOR" = "$MONITOR_1" ]; then
  hyprctl dispatch movecurrentworkspacetomonitor "$MONITOR_2"
else
  hyprctl dispatch movecurrentworkspacetomonitor "$MONITOR_1"
fi
