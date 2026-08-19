#!/bin/bash
# Blocks reads of vault notes tagged "private" in frontmatter, regardless of
# which agent/session/cwd triggered it. Covers Read, Grep, and simple Bash
# file-dumping commands (cat/head/tail/less/bat).
VAULT="$HOME/Desktop/the-vault"

is_private() {
  local f="$1"
  [ -f "$f" ] || return 1
  case "$f" in "$VAULT"/*) ;; *) return 1 ;; esac
  awk '/^---$/{n++; next} n==1' "$f" | grep -qE '^\s*-\s*private\s*$|^\s*private\s*:\s*true\s*$'
}

block() {
  echo "Blocked: '$1' is tagged private in frontmatter. Skip it." >&2
  exit 2
}

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

case "$tool" in
  Read)
    file=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    is_private "$file" && block "$file"
    ;;
  Grep)
    path=$(echo "$input" | jq -r '.tool_input.path // empty')
    [ -n "$path" ] || exit 0
    case "$path" in "$VAULT"|"$VAULT"/*) ;; *) exit 0 ;; esac
    if [ -f "$path" ]; then
      is_private "$path" && block "$path"
    elif [ -d "$path" ]; then
      pattern=$(echo "$input" | jq -r '.tool_input.pattern // empty')
      while IFS= read -r f; do
        is_private "$f" && block "$f (matched by grep in $path)"
      done < <(rg -l --no-messages -- "$pattern" "$path" 2>/dev/null)
    fi
    ;;
  Bash)
    cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
    # ponytail: word-splits the raw command string, so a path quoted or
    # embedded inside a -c script (python -c "...open('path')...") can dodge
    # this. Upgrade to actually parsing argv if that ever bites.
    case "$cmd" in
      cat\ *|head\ *|tail\ *|less\ *|bat\ *|more\ *|sed\ *|awk\ *|perl\ *|\
      python\ *|python3\ *|node\ *|ruby\ *|rg\ *|grep\ *|ack\ *)
        for word in $cmd; do
          case "$word" in
            "$VAULT"/*) is_private "$word" && block "$word" ;;
          esac
        done
        ;;
    esac
    ;;
esac
exit 0
