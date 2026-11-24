#!/usr/bin/env bash
# Claude Code status line.
#
# Segment 1: ponytail plugin badge (preserved as-is; prints nothing when inactive).
# Segment 2: a colored "lambda" indicator mirroring the shell prompt theme in
#            ~/.config/starship-lambda.toml (cyan lambda normally, green while
#            in vim mode -- there is no shell exit code to check here, so the
#            error/red state from that prompt has no Claude Code equivalent).
input="$(cat)"

# Newest installed ponytail version, so a plugin update does not break this.
ponytail_script="$(printf "%s\n" "$HOME"/.claude/plugins/cache/ponytail/ponytail/*/hooks/ponytail-statusline.sh | sort -V | tail -1)"
ponytail=""
if [ -f "$ponytail_script" ]; then
    ponytail="$(printf '%s' "$input" | bash "$ponytail_script")"
fi

vim_mode="$(printf '%s' "$input" | jq -r '.vim.mode // empty')"

if [ -n "$vim_mode" ]; then
    lambda="$(printf '\033[1;32m\316\273\033[0m')"   # bold green, matches vimcmd_symbol
else
    lambda="$(printf '\033[1;36m\316\273\033[0m')"   # bold cyan, matches success_symbol
fi

if [ -n "$ponytail" ]; then
    printf '%s %s' "$ponytail" "$lambda"
else
    printf '%s' "$lambda"
fi
