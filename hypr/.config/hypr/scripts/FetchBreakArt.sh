#!/usr/bin/env bash
# Download and process public-domain break art.
# Source: The Met Open Access (CC0).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_FILE="$HYPR_DIR/breakart/sources.tsv"
RAW_DIR="$HYPR_DIR/breakart/raw"
PROC_DIR="$HYPR_DIR/breakart/processed"

quiet=0
if [[ "${1:-}" == "--quiet" ]]; then
    quiet=1
fi

log() {
    if (( quiet == 0 )); then
        printf '%s\n' "$*"
    fi
}

if ! command -v curl >/dev/null 2>&1; then
    log "curl is required"
    exit 1
fi

mkdir -p "$RAW_DIR" "$PROC_DIR"

if [[ ! -f "$SOURCE_FILE" ]]; then
    log "missing art source list: $SOURCE_FILE"
    exit 1
fi

downloaded=0
processed=0

while IFS=$'\t' read -r slug object_id title artist object_date url; do
    [[ -z "$slug" || "$slug" == \#* ]] && continue

    raw_file="$RAW_DIR/${slug}.jpg"
    proc_file="$PROC_DIR/${slug}.jpg"

    if [[ ! -f "$raw_file" ]]; then
        if curl -fsSL "$url" -o "${raw_file}.tmp"; then
            mv "${raw_file}.tmp" "$raw_file"
            downloaded=$((downloaded + 1))
            log "downloaded: $slug"
        else
            rm -f "${raw_file}.tmp"
            log "failed download: $slug"
            continue
        fi
    fi

    if [[ ! -f "$proc_file" || "$raw_file" -nt "$proc_file" ]]; then
        if command -v magick >/dev/null 2>&1; then
            if [[ "$slug" == "pierced-window-screen" ]]; then
                # Keep one low-saturation color option.
                magick "$raw_file" \
                    -auto-orient \
                    -resize 3200x1800^ \
                    -gravity center \
                    -extent 3200x1800 \
                    -modulate 70,45,100 \
                    "$proc_file"
            else
                magick "$raw_file" \
                    -auto-orient \
                    -colorspace Gray \
                    -resize 3200x1800^ \
                    -gravity center \
                    -extent 3200x1800 \
                    -fill 'rgba(0,0,0,0.28)' \
                    -colorize 28 \
                    "$proc_file"
            fi
        else
            cp "$raw_file" "$proc_file"
        fi
        processed=$((processed + 1))
        log "processed: $slug"
    fi
done < "$SOURCE_FILE"

log "done: downloaded=$downloaded processed=$processed"
