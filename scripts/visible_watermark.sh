#!/bin/bash
# ponytail: tiled diagonal watermark, ImageMagick only, no external repo needed.
# Usage: watermark <image> ["Name to stamp"] [output path]
#   name defaults to ~/.c2pa/author.txt so you don't retype your own brand every time
set -e
in="$1"
name="${2:-$(cat "$HOME/.c2pa/author.txt" 2>/dev/null || echo "Your Brand Name")}"
out="${3:-${in%.*}-watermarked.${in##*.}}"
text="© $name"

dims=$(magick identify -format "%wx%h" "$in")
w=${dims%x*}
h=${dims#*x*}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# one rotated, subtle text tile — no stroke, low opacity, fills the whole image when tiled
magick -size 400x250 xc:none -gravity center -font "$HOME/Library/Fonts/Alice-Regular.ttf" -pointsize 24 \
  -fill "rgba(255,255,255,0.18)" \
  -annotate 0 "$text" -background none -rotate -30 -trim +repage "$tmp/tile.png"

# repeat the tile to cover the full image, then composite over original
magick -size "${w}x${h}" tile:"$tmp/tile.png" "$tmp/pattern.png"
magick "$in" "$tmp/pattern.png" -compose over -composite "$out"

echo "Watermarked: $out"
