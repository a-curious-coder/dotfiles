#!/bin/bash
# Blocks reads of vault notes tagged "private" in frontmatter, and of
# .obsidian/plugins files, regardless of which agent/session/cwd triggered it.
# Covers Read, Grep, and any Bash command that names a vault path.
# Fails closed: if it cannot parse its input, it blocks (exit 2).
VAULT="$HOME/Desktop/the-vault"

command -v jq >/dev/null 2>&1 || { echo "vault-private-guard: jq not found, blocking to be safe" >&2; exit 2; }

is_private() {
  local f="$1"
  [ -f "$f" ] || return 1
  case "$f" in "$VAULT"/*) ;; *) return 1 ;; esac
  awk '/^---$/{n++; next} n==1' "$f" | grep -qE '^\s*-\s*private\s*$|^\s*private\s*:\s*true\s*$'
}

# Plugin code and settings: secrets in data.json, minified noise in main.js.
# manifest.json is fine. User opts in with: touch ~/.claude/.allow-vault-plugins
is_plugin_file() {
  [ -e "$HOME/.claude/.allow-vault-plugins" ] && return 1
  case "$1" in
    "$VAULT"/.obsidian/plugins/*/manifest.json) return 1 ;;
    "$VAULT"/.obsidian/plugins|"$VAULT"/.obsidian/plugins/*) return 0 ;;
  esac
  return 1
}

block() {
  echo "Blocked: '$1' is tagged private in frontmatter. Skip it." >&2
  exit 2
}

block_plugin() {
  echo "Blocked: '$1' is in .obsidian/plugins (secrets, minified code). Ask the user to run: touch ~/.claude/.allow-vault-plugins" >&2
  exit 2
}

check() {
  is_plugin_file "$1" && block_plugin "$1"
  is_private "$1" && block "$1"
}

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty') || { echo "vault-private-guard: bad hook input, blocking" >&2; exit 2; }
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

# Resolve a path the way the tool will: ~ and relative-to-cwd.
resolve() {
  local p="$1"
  case "$p" in
    "~"/*) p="$HOME/${p#\~/}" ;;
    /*) ;;
    *) [ -n "$cwd" ] && p="$cwd/$p" ;;
  esac
  printf '%s' "$p"
}

case "$tool" in
  Read)
    file=$(resolve "$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')")
    check "$file"
    ;;
  Grep)
    path=$(printf '%s' "$input" | jq -r '.tool_input.path // empty')
    path=$(resolve "${path:-.}")
    case "$path" in "$VAULT"|"$VAULT"/*|"$VAULT"/.) ;; *) exit 0 ;; esac
    if [ -f "$path" ]; then
      check "$path"
    elif [ -d "$path" ]; then
      is_plugin_file "$path" && block_plugin "$path"
      pattern=$(printf '%s' "$input" | jq -r '.tool_input.pattern // empty')
      while IFS= read -r f; do
        is_private "$f" && block "$f (matched by grep in $path)"
      done < <(rg -l --no-messages -- "$pattern" "$path" 2>/dev/null)
    fi
    ;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    # Check every word, not just the first command: `cd x && cat note` and
    # pipelines are covered. Quotes and shell punctuation are stripped first.
    # xargs splits the way the shell quotes ("Secret note.md" stays one word);
    # the plain split still runs too, for input xargs rejects (unmatched quote).
    # shortcut: a path built at runtime (python -c "open(base+'/x')") still
    # dodges this; parse argv properly if that ever bites.
    # shellcheck disable=SC2086  # unquoted $cmd below is the plain split
    while IFS= read -r word; do
      word="${word//[\"\'\(\)\;\|\&\<\>]/}"
      [ -n "$word" ] || continue
      check "$(resolve "$word")"
    done < <(printf '%s' "$cmd" | xargs printf '%s\n' 2>/dev/null; printf '%s\n' $cmd)
    ;;
esac
exit 0
