#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Searching via web browsers

# Define the path to the config file
config_file=$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Process the config file in memory, removing the $ and fixing spaces
config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')

# Source the modified content directly from the variable
eval "$config_content"

# Check if $term is set correctly
if [[ -z "$Search_Engine" ]]; then
    echo "Error: \$Search_Engine is not set in the configuration file!"
    exit 1
fi

# Rofi theme
rofi_theme="$HOME/.config/rofi/config-search.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Open rofi and pass the selected query to the default browser
query="$(rofi -dmenu -config "$rofi_theme" | xargs)"
[ -n "$query" ] || exit 0

encoded_query="$(printf '%s' "$query" | sed 's/[[:space:]]\\+/+/g')"
search_url="${Search_Engine/\{\}/$encoded_query}"

xdg-open "$search_url"
