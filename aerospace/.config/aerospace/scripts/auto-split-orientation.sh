#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace"
LOCK_DIR="$STATE_DIR/auto-split-lock"
SUPPRESS_DIR="$STATE_DIR/hypr-dwindle-callback-suppress"
LOG_FILE="$STATE_DIR/hypr-dwindle.log"
MAX_HISTORY="${AEROSPACE_DWINDLE_HISTORY_LIMIT:-12}"
AERO_TIMEOUT_SECONDS="${AEROSPACE_DWINDLE_TIMEOUT_SECONDS:-1}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$STATE_DIR"

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  local stale_pid=""
  stale_pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [[ "$stale_pid" =~ ^[0-9]+$ ]] && kill -0 "$stale_pid" 2>/dev/null; then
    return 1
  fi

  rm -rf "$LOCK_DIR" >/dev/null 2>&1 || true
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  return 1
}

acquire_suppress_lock() {
  if mkdir "$SUPPRESS_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$SUPPRESS_DIR/pid"
    return 0
  fi

  local stale_pid=""
  stale_pid="$(cat "$SUPPRESS_DIR/pid" 2>/dev/null || true)"
  if [[ "$stale_pid" =~ ^[0-9]+$ ]] && kill -0 "$stale_pid" 2>/dev/null; then
    return 1
  fi

  rm -rf "$SUPPRESS_DIR" >/dev/null 2>&1 || true
  if mkdir "$SUPPRESS_DIR" 2>/dev/null; then
    printf '%s\n' "$$" > "$SUPPRESS_DIR/pid"
    return 0
  fi

  return 1
}

if ! acquire_lock; then
  exit 0
fi

cleanup() {
  rm -rf "$LOCK_DIR" >/dev/null 2>&1 || true
  if [ -f "$SUPPRESS_DIR/pid" ] && [ "$(cat "$SUPPRESS_DIR/pid" 2>/dev/null || true)" = "$$" ]; then
    rm -rf "$SUPPRESS_DIR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

acquire_suppress_lock || true

log_debug() {
  printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*" >> "$LOG_FILE"
}

aero_run() {
  perl -e '
    my $seconds = shift @ARGV;
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;
    if ($pid == 0) {
      exec @ARGV or die "exec failed: $!\n";
    }
    eval {
      local $SIG{ALRM} = sub { die "timeout\n" };
      alarm($seconds);
      waitpid($pid, 0);
      alarm(0);
    };
    if ($@) {
      kill "TERM", $pid;
      waitpid($pid, 0);
      exit 124 if $@ =~ /timeout/;
      die $@;
    }
    exit(($? >> 8) || 0);
  ' "$AERO_TIMEOUT_SECONDS" "$@"
}

aero_capture() {
  perl -e '
    my $seconds = shift @ARGV;
    pipe(my $reader, my $writer) or die "pipe failed: $!\n";
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;
    if ($pid == 0) {
      close $reader;
      open STDOUT, ">&", $writer or die "dup stdout failed: $!\n";
      open STDERR, ">/dev/null" or die "stderr redirect failed: $!\n";
      exec @ARGV or die "exec failed: $!\n";
    }
    close $writer;
    my $output = q{};
    eval {
      local $SIG{ALRM} = sub { die "timeout\n" };
      alarm($seconds);
      local $/;
      $output = <$reader> // q{};
      alarm(0);
    };
    close $reader;
    if ($@) {
      kill "TERM", $pid;
      waitpid($pid, 0);
      exit 124 if $@ =~ /timeout/;
      die $@;
    }
    waitpid($pid, 0);
    exit(($? >> 8) || 0) if $? != 0;
    print $output;
  ' "$AERO_TIMEOUT_SECONDS" "$@"
}

workspace_key() {
  printf '%s' "$1" | tr -cs '[:alnum:]._-' '_'
}

model_file() {
  printf '%s/hypr-dwindle-model-%s.tsv\n' "$STATE_DIR" "$(workspace_key "$1")"
}

history_file() {
  printf '%s/hypr-dwindle-focus-history-%s.tsv\n' "$STATE_DIR" "$(workspace_key "$1")"
}

marker_file() {
  printf '%s/hypr-dwindle-presplit-%s\n' "$STATE_DIR" "$(workspace_key "$1")"
}

snapshot_file() {
  printf '%s/hypr-dwindle-live-%s.tsv\n' "$STATE_DIR" "$(workspace_key "$1")"
}

resolve_workspace_name() {
  local workspace="${1:-}"
  if [ "$workspace" = 'focused' ]; then
    aero_capture "$AERO_BIN" list-workspaces --focused --format '%{workspace}' | awk 'NF { print; exit }'
    return
  fi
  printf '%s' "$workspace"
}

list_workspace_ids() {
  aero_capture "$AERO_BIN" list-windows --workspace "$1" --format '%{window-id}' | awk 'NF'
}

current_workspace_names() {
  aero_capture "$AERO_BIN" list-workspaces --all --format '%{workspace}' | awk 'NF'
}

count_lines() {
  local input="${1:-}"
  printf '%s\n' "$input" | awk 'NF { c++ } END { print c + 0 }'
}

contains_id() {
  local ids="${1:-}"
  local target="${2:-}"
  case $'\n'"$ids"$'\n' in
    *$'\n'"$target"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

ids_blob() {
  local input="${1:-}"
  printf '%s\n' "$input" | awk 'NF { printf "|%s", $0 } END { print "|" }'
}

trim_slashes() {
  local value="${1:-}"
  value="${value#/}"
  value="${value%/}"
  printf '%s' "$value"
}

join_path() {
  local base="${1:-}"
  local child="${2:-}"
  if [ -z "$base" ]; then
    printf '%s' "$child"
  else
    printf '%s/%s' "$base" "$child"
  fi
}

layout_for_anchor_path() {
  local path="${1:-}"
  if [ -z "$path" ]; then
    printf 'horizontal'
    return
  fi

  case "${path##*/}" in
    L|R) printf 'vertical' ;;
    U|D) printf 'horizontal' ;;
    *) printf 'horizontal' ;;
  esac
}

get_model_path() {
  local file="${1:-}"
  local window_id="${2:-}"
  awk -F'\t' -v wid="$window_id" '$1 == wid { print $2; found = 1; exit } END { if (!found) exit 1 }' "$file" 2>/dev/null
}

write_model_line() {
  local file="${1:-}"
  local window_id="${2:-}"
  local path="${3:-}"
  printf '%s\t%s\n' "$window_id" "$path" >> "$file"
}

insert_into_model() {
  local file="${1:-}"
  local anchor_id="${2:-}"
  local new_id="${3:-}"
  local desired_layout="${4:-}"
  local anchor_path=""

  anchor_path="$(get_model_path "$file" "$anchor_id" 2>/dev/null || true)"
  if [ -z "$anchor_path" ] && ! awk -F'\t' -v wid="$anchor_id" '$1 == wid { found = 1; exit } END { exit(found ? 0 : 1) }' "$file" 2>/dev/null; then
    return 1
  fi

  local anchor_child='L'
  local new_child='R'
  if [ "$desired_layout" = 'vertical' ]; then
    anchor_child='U'
    new_child='D'
  fi

  local anchor_parent=""
  anchor_parent="$(trim_slashes "$anchor_path")"
  local updated_anchor=""
  updated_anchor="$(join_path "$anchor_parent" "$anchor_child")"
  local new_path=""
  new_path="$(join_path "$anchor_parent" "$new_child")"

  awk -F'\t' -v OFS='\t' -v wid="$anchor_id" -v path="$updated_anchor" '
    $1 == wid { $2 = path }
    { print }
  ' "$file" > "${file}.tmp"
  mv "${file}.tmp" "$file"
  write_model_line "$file" "$new_id" "$new_path"
}

build_sequential_model() {
  local file="${1:-}"
  local ids="${2:-}"
  : > "$file"

  local anchor_id=""
  local current_id=""
  while IFS= read -r current_id; do
    [ -n "$current_id" ] || continue
    if [ -z "$anchor_id" ]; then
      write_model_line "$file" "$current_id" ""
      anchor_id="$current_id"
      continue
    fi

    local desired_layout=""
    desired_layout="$(layout_for_anchor_path "$(get_model_path "$file" "$anchor_id" 2>/dev/null || true)")"
    insert_into_model "$file" "$anchor_id" "$current_id" "$desired_layout"
    anchor_id="$current_id"
  done <<< "$ids"
}

prune_focus_history() {
  local file="${1:-}"
  local live_ids="${2:-}"
  [ -f "$file" ] || return 0
  local live_blob=""
  live_blob="$(ids_blob "$live_ids")"

  awk -v live="$live_blob" -v limit="$MAX_HISTORY" '
    function contains(list, value) {
      return index(list, "|" value "|") > 0
    }
    NF && contains(live, $1) && !seen[$1] {
      print $1
      seen[$1] = 1
      count++
      if (count >= limit) {
        exit
      }
    }
  ' "$file" > "${file}.tmp"
  mv "${file}.tmp" "$file"
}

anchor_from_history() {
  local file="${1:-}"
  local live_ids="${2:-}"
  local excluded_ids="${3:-}"
  [ -f "$file" ] || return 1
  local live_blob=""
  local excluded_blob=""
  live_blob="$(ids_blob "$live_ids")"
  excluded_blob="$(ids_blob "$excluded_ids")"

  awk -v live="$live_blob" -v excluded="$excluded_blob" '
    function contains(list, value) {
      return index(list, "|" value "|") > 0
    }
    NF && contains(live, $1) && !contains(excluded, $1) {
      print $1
      exit
    }
  ' "$file"
}

record_snapshot() {
  local workspace="${1:-}"
  local live_ids="${2:-}"
  printf '%s\n' "$live_ids" | awk 'NF' > "$(snapshot_file "$workspace")"
}

collapse_workspace() {
  local workspace="${1:-}"
  local live_ids="${2:-}"
  local file=""

  file="$(model_file "$workspace")"
  aero_run "$AERO_BIN" flatten-workspace-tree --workspace "$workspace" >/dev/null 2>&1 || true
  aero_run "$AERO_BIN" balance-sizes --workspace "$workspace" >/dev/null 2>&1 || true
  build_sequential_model "$file" "$live_ids"
  prune_focus_history "$(history_file "$workspace")" "$live_ids"
  rm -f "$(marker_file "$workspace")" >/dev/null 2>&1 || true
  log_debug "workspace=$workspace action=collapse count=$(count_lines "$live_ids")"
}

register_new_windows() {
  local workspace="${1:-}"
  local live_ids="${2:-}"
  local new_ids="${3:-}"
  local file=""
  file="$(model_file "$workspace")"

  [ -f "$file" ] || build_sequential_model "$file" "$live_ids"

  local window_id=""
  while IFS= read -r window_id; do
    [ -n "$window_id" ] || continue

    local anchor_id=""
    anchor_id="$(anchor_from_history "$(history_file "$workspace")" "$live_ids" "$new_ids" || true)"
    if [ -z "$anchor_id" ]; then
      anchor_id="$(awk -F'\t' -v current="$window_id" '$1 != current { print $1; exit }' "$file" 2>/dev/null || true)"
    fi

    if [ -z "$anchor_id" ]; then
      if ! awk -F'\t' -v wid="$window_id" '$1 == wid { found = 1; exit } END { exit(found ? 0 : 1) }' "$file" 2>/dev/null; then
        write_model_line "$file" "$window_id" ""
      fi
      continue
    fi

    if awk -F'\t' -v wid="$window_id" '$1 == wid { found = 1; exit } END { exit(found ? 0 : 1) }' "$file" 2>/dev/null; then
      continue
    fi

    local anchor_path=""
    anchor_path="$(get_model_path "$file" "$anchor_id" 2>/dev/null || true)"
    local desired_layout=""
    desired_layout="$(layout_for_anchor_path "$anchor_path")"
    insert_into_model "$file" "$anchor_id" "$window_id" "$desired_layout" || true
    log_debug "workspace=$workspace action=register-new anchor=$anchor_id new=$window_id desired=$desired_layout"
  done <<< "$new_ids"

  prune_focus_history "$(history_file "$workspace")" "$live_ids"
  rm -f "$(marker_file "$workspace")" >/dev/null 2>&1 || true
}

repair_workspace() {
  local workspace="${1:-focused}"
  local live_ids=""

  workspace="$(resolve_workspace_name "$workspace")"
  [ -n "$workspace" ] || return 0
  live_ids="$(list_workspace_ids "$workspace")"

  if [ "$(count_lines "$live_ids")" -eq 0 ]; then
    rm -f "$(model_file "$workspace")" "$(history_file "$workspace")" "$(snapshot_file "$workspace")" "$(marker_file "$workspace")" >/dev/null 2>&1 || true
    return 0
  fi

  collapse_workspace "$workspace" "$live_ids"
  record_snapshot "$workspace" "$live_ids"
}

reconcile_workspace() {
  local workspace="${1:-}"
  [ -n "$workspace" ] || return 0

  local live_ids=""
  local previous_ids=""
  local file=""
  local marker_path=""
  local new_ids=""
  local removed_ids=""
  local window_id=""

  live_ids="$(list_workspace_ids "$workspace")"
  file="$(model_file "$workspace")"
  marker_path="$(marker_file "$workspace")"

  if [ "$(count_lines "$live_ids")" -eq 0 ]; then
    rm -f "$file" "$(history_file "$workspace")" "$(snapshot_file "$workspace")" "$marker_path" >/dev/null 2>&1 || true
    return 0
  fi

  previous_ids="$(cat "$(snapshot_file "$workspace")" 2>/dev/null || true)"

  while IFS= read -r window_id; do
    [ -n "$window_id" ] || continue
    if ! contains_id "$live_ids" "$window_id"; then
      removed_ids="${removed_ids}${window_id}"$'\n'
    fi
  done <<< "$previous_ids"

  while IFS= read -r window_id; do
    [ -n "$window_id" ] || continue
    if ! contains_id "$previous_ids" "$window_id"; then
      new_ids="${new_ids}${window_id}"$'\n'
    fi
  done <<< "$live_ids"

  if [ -n "$removed_ids" ]; then
    collapse_workspace "$workspace" "$live_ids"
    record_snapshot "$workspace" "$live_ids"
    return 0
  fi

  if [ -n "$new_ids" ]; then
    register_new_windows "$workspace" "$live_ids" "$new_ids"
    record_snapshot "$workspace" "$live_ids"
    return 0
  fi

  if [ -f "$marker_path" ] && [ ! -f "$file" ]; then
    build_sequential_model "$file" "$live_ids"
    rm -f "$marker_path" >/dev/null 2>&1 || true
  fi

  prune_focus_history "$(history_file "$workspace")" "$live_ids"
  record_snapshot "$workspace" "$live_ids"
}

if [ "${1:-}" = '--repair' ]; then
  repair_workspace "${2:-focused}"
  exit 0
fi

workspace_names="$(current_workspace_names)"
for workspace in $workspace_names; do
  reconcile_workspace "$workspace"
done
