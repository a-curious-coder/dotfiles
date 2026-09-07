#!/bin/sh
# Fetch the live herdr plugin registry and compare it against what's installed.
# Usage: audit.sh [top-n]   (default top-n = 40)
set -eu

TOP="${1:-40}"
CACHE="${TMPDIR:-/tmp}/herdr-plugins-index.json"
INSTALLED="$HOME/.config/herdr/plugins.json"

curl -sf 'https://assets.herdr.dev/plugins/index.json' \
  --compressed \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:155.0) Gecko/20100101 Firefox/155.0' \
  -H 'Accept: application/json' \
  -H 'Referer: https://herdr.dev/' \
  -H 'Origin: https://herdr.dev' \
  -o "$CACHE"

echo "== Registry: top $TOP by stars =="
jq -r '.plugins[] | [.stars, (.manifests[0].id // .name), .fullName, .description] | @tsv' "$CACHE" \
  | sort -t $'\t' -k1 -rn | head -n "$TOP" \
  | awk -F'\t' '{printf "%-6s %-28s %-35s %s\n", $1, $2, $3, $4}'

if [ -f "$INSTALLED" ]; then
  echo
  echo "== Installed plugins, with current registry star count =="
  jq -r '.[].plugin_id' "$INSTALLED" | while read -r id; do
    star=$(jq -r --arg id "$id" '.plugins[] | select((.manifests[0].id // .name) == $id) | .stars' "$CACHE" | head -1)
    printf "%-6s %s\n" "${star:-?}" "$id"
  done | sort -rn
fi
