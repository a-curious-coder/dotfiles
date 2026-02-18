#!/usr/bin/env bash
# Minimal break-screen launcher for hyprlock.
# --random (default): random art background if available, else random minimal theme.
# --fixed [theme]: use one consistent minimal theme.
# --random-theme: force random minimal theme.

set -euo pipefail

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
THEME_DIR="$HYPR_DIR/breakthemes"
ART_DIR="$HYPR_DIR/breakart/processed"
FALLBACK="$HYPR_DIR/hyprbreak.conf"
FETCH_SCRIPT="$SCRIPT_DIR/FetchBreakArt.sh"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
ART_CONFIG="$CACHE_DIR/hyprbreak-art.conf"
DEFAULT_FIXED_THEME="noir-orbit"

themes=(
    "noir-orbit"
    "noir-grid"
    "paper-ink"
    "slate-accent"
)

mode="${1:---random}"
requested_theme="${2:-}"
case "$mode" in
    --random | --random-art | --art) mode="--random-art" ;;
    --random-theme) ;;
    --fixed) ;;
    *) mode="--random-art" ;;
esac

pick_random_theme() {
    local selected
    selected="${themes[RANDOM % ${#themes[@]}]}"
    local config="$THEME_DIR/$selected.conf"
    if [[ ! -f "$config" ]]; then
        config="$FALLBACK"
    fi
    exec hyprlock -c "$config"
}

ensure_art_assets() {
    if compgen -G "$ART_DIR/*.jpg" >/dev/null || compgen -G "$ART_DIR/*.png" >/dev/null; then
        return 0
    fi
    if [[ -x "$FETCH_SCRIPT" ]]; then
        "$FETCH_SCRIPT" --quiet >/dev/null 2>&1 || true
    fi
}

pick_random_art() {
    [[ -d "$ART_DIR" ]] || return 1
    local -a art_files=()
    while IFS= read -r file; do
        art_files+=("$file")
    done < <(find "$ART_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' \) | sort)
    if (( ${#art_files[@]} == 0 )); then
        return 1
    fi
    local art
    art="${art_files[RANDOM % ${#art_files[@]}]}"

    mkdir -p "$CACHE_DIR"
    cat > "$ART_CONFIG" <<EOF
general {
    grace = 1
    hide_cursor = true
    immediate_render = true
}
background {
    monitor =
    path = $art
    color = rgb(10, 10, 10)
    blur_passes = 0
}
label {
    monitor =
    text = cmd[update:1000] date +"%H:%M"
    color = rgb(232, 232, 232)
    font_size = 108
    font_family = JetBrainsMono Nerd Font
    position = 0, 170
    halign = center
    valign = center
    shadow_passes = 1
    shadow_size = 5
    shadow_color = rgb(0, 0, 0)
}
label {
    monitor =
    text = cmd[update:60000] date +"%A, %d %B"
    color = rgb(165, 165, 165)
    font_size = 18
    font_family = JetBrainsMono Nerd Font
    position = 0, 90
    halign = center
    valign = center
}
input-field {
    monitor =
    size = 220, 40
    outline_thickness = 1
    dots_size = 0.22
    dots_spacing = 0.3
    dots_center = true
    outer_color = rgb(112, 112, 112)
    inner_color = rgb(18, 18, 18)
    font_color = rgb(220, 220, 220)
    fade_on_empty = true
    placeholder_text =
    hide_input = true
    position = 0, -120
    halign = center
    valign = center
    rounding = 0
}
EOF
    exec hyprlock -c "$ART_CONFIG"
}

if [[ "$mode" == "--fixed" ]]; then
    if [[ -n "$requested_theme" ]]; then
        selected="$requested_theme"
    else
        selected="${HYPR_BREAK_THEME:-$DEFAULT_FIXED_THEME}"
    fi
    config="$THEME_DIR/$selected.conf"
    if [[ ! -f "$config" ]]; then
        config="$FALLBACK"
    fi
    exec hyprlock -c "$config"
fi

if [[ "$mode" == "--random-theme" ]]; then
    pick_random_theme
fi

ensure_art_assets
pick_random_art || pick_random_theme
