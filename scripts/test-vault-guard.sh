#!/usr/bin/env bash
# Behaviour tests for claude/.claude/hooks/vault-private-guard.sh against a
# throwaway vault (the hook reads $HOME, so a temp HOME is enough).
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
guard="$repo_root/claude/.claude/hooks/vault-private-guard.sh"

for cmd in jq rg; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required" >&2; exit 1; }
done

home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
vault="$home/Desktop/the-vault"
mkdir -p "$vault/.obsidian/plugins/x"
printf -- '---\ntags:\n  - private\n---\nsecret\n' >"$vault/Secret note.md"
printf -- '---\ntags:\n  - ai-drafted\n---\nfine\n' >"$vault/Public note.md"
echo '{}' >"$vault/.obsidian/plugins/x/data.json"
echo '{}' >"$vault/.obsidian/plugins/x/manifest.json"

fail=0
expect() { # expect <exit code> <label> <hook input>
  local got
  printf '%s' "$3" | HOME="$home" bash "$guard" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$1" ]; then echo "ok   $2"; else echo "FAIL $2 (exit $got, want $1)"; fail=1; fi
}
input() { # input <tool> <key> <value> <cwd>
  jq -nc --arg t "$1" --arg k "$2" --arg v "$3" --arg c "$4" '{tool_name:$t,cwd:$c,tool_input:{($k):$v}}'
}

expect 2 "Read private note"          "$(input Read file_path "$vault/Secret note.md" /tmp)"
expect 0 "Read public note"           "$(input Read file_path "$vault/Public note.md" /tmp)"
# shellcheck disable=SC2088  # a literal ~ is the input under test
expect 2 "Read via ~ path"           "$(input Read file_path "~/Desktop/the-vault/Secret note.md" /tmp)"
expect 2 "Bash cd && cat"             "$(input Bash command "cd /tmp && cat '$vault/Secret note.md'" /tmp)"
expect 2 "Bash relative path"         "$(input Bash command 'cat "Secret note.md"' "$vault")"
expect 2 "Grep vault, no path"        "$(jq -nc --arg c "$vault" '{tool_name:"Grep",cwd:$c,tool_input:{pattern:"secret"}}')"
expect 2 "Read plugin data.json"      "$(input Read file_path "$vault/.obsidian/plugins/x/data.json" /tmp)"
expect 0 "Read plugin manifest.json"  "$(input Read file_path "$vault/.obsidian/plugins/x/manifest.json" /tmp)"
expect 0 "Read outside vault"         "$(input Read file_path /etc/hosts /tmp)"
expect 2 "Malformed input fails closed" "not json"

exit "$fail"
