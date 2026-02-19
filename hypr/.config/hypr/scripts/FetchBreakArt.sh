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
declare -a valid_slugs=()

while IFS=$'\t' read -r slug object_id title artist object_date url; do
    [[ -z "$slug" || "$slug" == \#* ]] && continue
    valid_slugs+=("$slug")

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

    if [[ ! -f "$proc_file" || "$raw_file" -nt "$proc_file" || "$0" -nt "$proc_file" ]]; then
        if command -v magick >/dev/null 2>&1; then
            # Keep composition intact: fit inside frame, then letterbox.
            magick "$raw_file" \
                -auto-orient \
                -resize 3840x2160 \
                -background '#0b0b0b' \
                -gravity center \
                -extent 3840x2160 \
                -modulate 92,45,100 \
                -fill 'rgba(0,0,0,0.16)' \
                -colorize 16 \
                "$proc_file"
        else
            cp "$raw_file" "$proc_file"
        fi
        processed=$((processed + 1))
        log "processed: $slug"
    fi
done < "$SOURCE_FILE"

# prune stale files no longer in the curated source list
for dir in "$RAW_DIR" "$PROC_DIR"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r path; do
        base="$(basename "$path")"
        stem="${base%.*}"
        keep=0
        for slug in "${valid_slugs[@]}"; do
            if [[ "$stem" == "$slug" ]]; then
                keep=1
                break
            fi
        done
        if (( keep == 0 )); then
            rm -f "$path"
            log "pruned: $base"
        fi
    done < <(find "$dir" -maxdepth 1 -type f)
done

log "done: downloaded=$downloaded processed=$processed"
