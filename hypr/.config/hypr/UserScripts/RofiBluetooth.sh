#!/bin/bash
# Rofi menu to connect/disconnect paired Bluetooth devices, or scan+pair new ones.

rofi_theme="$HOME/.config/rofi/config-bluetooth.rasi"
scan_entry="  Scan for new devices"

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

list_paired() {
    bluetoothctl devices Paired | while read -r _ mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            echo "[connected]    $name"
        else
            echo "[available]    $name"
        fi
    done
}

mac_for_name() {
    bluetoothctl devices Paired | grep -F " $1$" | awk '{print $2}'
}

scan_new() {
    bluetoothctl --timeout 8 scan on >/dev/null
    bluetoothctl devices | while read -r _ mac name; do
        bluetoothctl info "$mac" | grep -q "Paired: yes" || echo "$mac $name"
    done
}

choice=$(
    { echo "$scan_entry"; list_paired; } |
        rofi -i -dmenu -mesg "Toggle connect/disconnect, or scan for a new device" -config "$rofi_theme"
)

[ -z "$choice" ] && exit

if [ "$choice" = "$scan_entry" ]; then
    found=$(scan_new)
    [ -z "$found" ] && { notify-send "Bluetooth" "No new devices found"; exit; }

    pick=$(echo "$found" | awk '{$1=""; print substr($0,2)}' |
        rofi -i -dmenu -mesg "Select a device to pair" -config "$rofi_theme")
    [ -z "$pick" ] && exit

    mac=$(echo "$found" | grep -F " $pick" | awk '{print $1}')
    bluetoothctl pair "$mac" && bluetoothctl trust "$mac" && bluetoothctl connect "$mac"
    notify-send "Bluetooth" "Paired and connected: $pick"
    exit
fi

name="${choice#*]    }"
mac=$(mac_for_name "$name")

if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac"
    notify-send "Bluetooth" "Disconnected: $name"
else
    bluetoothctl connect "$mac"
    notify-send "Bluetooth" "Connected: $name"
fi
