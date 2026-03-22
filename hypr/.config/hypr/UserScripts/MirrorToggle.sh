#!/bin/bash
# Toggle mirror mode: mirror all other outputs to the focused monitor.
# Off → restores kanshi's profile for connected outputs.

STATE_FILE="/tmp/hypr_mirror_active"

FOCUSED=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')

if [ -f "$STATE_FILE" ]; then
    # Reset each saved monitor, then let kanshi restore the layout
    while read -r monitor; do
        hyprctl keyword monitor "$monitor,preferred,auto,1"
    done < "$STATE_FILE"
    rm "$STATE_FILE"
    kanshictl reload
    notify-send -i display "Mirror Off" "Restored display profiles"
else
    # Save mirrored monitor names before they disappear from hyprctl monitors
    hyprctl monitors -j | jq -r '.[].name' | while read -r monitor; do
        [ "$monitor" = "$FOCUSED" ] && continue
        echo "$monitor" >> "$STATE_FILE"
        hyprctl keyword monitor "$monitor,preferred,auto,1,mirror,$FOCUSED"
    done
    notify-send -i display "Mirror On" "Mirroring outputs to $FOCUSED"
fi
