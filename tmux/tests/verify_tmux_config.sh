#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${CONFIG_PATH:-$ROOT_DIR/.tmux.conf}"
SOCKET_NAME="tmux-config-test-$$"
SESSION_NAME="tmux_config_test"

pass_count=0
fail_count=0

cleanup() {
  tmux -L "$SOCKET_NAME" kill-server >/dev/null 2>&1 || true
}
trap cleanup EXIT

pass() {
  printf 'PASS: %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  fail_count=$((fail_count + 1))
}

assert_contains() {
  local test_name="$1"
  local haystack="$2"
  local needle="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$test_name"
  else
    printf '  Expected to find: %s\n' "$needle"
    printf '  Actual output did not include expected text\n'
    fail "$test_name"
  fi
}

assert_not_contains() {
  local test_name="$1"
  local haystack="$2"
  local needle="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    printf '  Did not expect to find: %s\n' "$needle"
    printf '  Actual output still included unexpected text\n'
    fail "$test_name"
  else
    pass "$test_name"
  fi
}

if [[ ! -f "$CONFIG_PATH" ]]; then
  printf 'Config not found at %s\n' "$CONFIG_PATH"
  exit 1
fi

if ! tmux -L "$SOCKET_NAME" -f /dev/null new-session -d -s "$SESSION_NAME" >/dev/null 2>&1; then
  printf 'Unable to start tmux test server\n'
  exit 1
fi

if source_output="$(tmux -L "$SOCKET_NAME" source-file "$CONFIG_PATH" 2>&1)"; then
  pass "tmux sources .tmux.conf without runtime/syntax errors"
else
  printf 'tmux source-file output:\n%s\n' "$source_output"
  fail "tmux sources .tmux.conf without runtime/syntax errors"
fi

# Test 1: True-color config stays compatible by using terminal-features with Tc fallback.
terminal_features="$(tmux -L "$SOCKET_NAME" show-options -g terminal-features 2>/dev/null || true)"
terminal_overrides="$(tmux -L "$SOCKET_NAME" show-options -g terminal-overrides 2>/dev/null || true)"
if [[ "$terminal_features" == *"RGB"* || "$terminal_overrides" == *":Tc"* ]]; then
  pass "true-color support is configured via RGB features and/or Tc fallback"
else
  printf 'terminal-features: %s\n' "$terminal_features"
  printf 'terminal-overrides: %s\n' "$terminal_overrides"
  fail "true-color support is configured via RGB features and/or Tc fallback"
fi

# Test 2: C-s flow-control mitigation exists so prefix is not intercepted by terminal XON/XOFF.
client_attached_hook="$(tmux -L "$SOCKET_NAME" show-hooks -g client-attached 2>/dev/null || true)"
assert_contains "client-attached hook disables ixon/ixoff for C-s prefix" "$client_attached_hook" "stty -ixon -ixoff"
prefix_value="$(tmux -L "$SOCKET_NAME" show-options -g prefix 2>/dev/null || true)"
assert_contains "prefix key remains mapped to C-s" "$prefix_value" "C-s"

# Test 3: Session switcher uses robust session names and avoids xargs/sed parsing.
session_picker_binding="$(tmux -L "$SOCKET_NAME" list-keys -T root M-e 2>/dev/null || true)"
assert_contains "M-e session picker uses list-sessions format output" "$session_picker_binding" "list-sessions -F '#S'"
assert_not_contains "M-e session picker no longer uses sed parsing" "$session_picker_binding" "sed -E"
assert_not_contains "M-e session picker no longer pipes into xargs" "$session_picker_binding" "xargs"

# Test 4: Clipboard copy binding is dynamic and still has a safe fallback copy action.
copy_mode_binding="$(tmux -L "$SOCKET_NAME" list-keys -T copy-mode-vi y 2>/dev/null || true)"
assert_contains "copy-mode y binding uses dynamic clipboard command option" "$copy_mode_binding" "#{@clipboard_copy_command}"
assert_contains "copy-mode y binding falls back to copy-selection-and-cancel" "$copy_mode_binding" "copy-selection-and-cancel"

clipboard_value="$(tmux -L "$SOCKET_NAME" show-options -gqv @clipboard_copy_command 2>/dev/null || true)"
clipboard_tool_available=false
if command -v xclip >/dev/null 2>&1 || command -v wl-copy >/dev/null 2>&1 || command -v pbcopy >/dev/null 2>&1; then
  clipboard_tool_available=true
fi

if [[ "$clipboard_tool_available" == "true" ]]; then
  if [[ -n "$clipboard_value" ]]; then
    pass "clipboard command is selected when a clipboard tool is installed"
  else
    fail "clipboard command is selected when a clipboard tool is installed"
  fi
else
  if [[ -z "$clipboard_value" ]]; then
    pass "clipboard command remains empty when no clipboard tool is installed"
  else
    fail "clipboard command remains empty when no clipboard tool is installed"
  fi
fi

# Test 5: Removed dead environment variable and replaced with real current-path window bindings.
global_env="$(tmux -L "$SOCKET_NAME" show-environment -g 2>/dev/null || true)"
assert_not_contains "unused tmux_conf_new_session_retain_current_path variable is absent" "$global_env" "tmux_conf_new_session_retain_current_path="

renumber_windows="$(tmux -L "$SOCKET_NAME" show-options -g renumber-windows 2>/dev/null || true)"
assert_contains "renumber-windows is enabled for compact tab ordering" "$renumber_windows" "on"

prefix_c_binding="$(tmux -L "$SOCKET_NAME" list-keys -T prefix c 2>/dev/null || true)"
assert_contains "prefix+c opens windows in current pane directory" "$prefix_c_binding" "new-window -c \"#{pane_current_path}\""
f2_binding="$(tmux -L "$SOCKET_NAME" list-keys -T root F2 2>/dev/null || true)"
assert_contains "F2 opens windows in current pane directory" "$f2_binding" "new-window -c \"#{pane_current_path}\""

# Test 6: Prefix+r reloads tmux config and provides confirmation message.
reload_binding="$(tmux -L "$SOCKET_NAME" list-keys -T prefix r 2>/dev/null || true)"
assert_contains "prefix+r is wired to source-file" "$reload_binding" "source-file "
assert_contains "prefix+r points at the tmux config file" "$reload_binding" ".tmux.conf"
assert_contains "prefix+r displays a reload confirmation message" "$reload_binding" "tmux config reloaded"

help_binding="$(tmux -L "$SOCKET_NAME" list-keys -T prefix '?' 2>/dev/null || true)"
assert_contains "prefix+? uses tmux-which-key launcher command" "$help_binding" "show-wk-menu-root"
assert_contains "prefix+? has popup help fallback when plugin is unavailable" "$help_binding" "tmux-help-popup.sh"

help_popup_binding="$(tmux -L "$SOCKET_NAME" list-keys -T prefix H 2>/dev/null || true)"
assert_contains "prefix+H opens the reference help popup" "$help_popup_binding" "display-popup"
assert_contains "prefix+H reference popup uses tmux-help-popup.sh" "$help_popup_binding" "tmux-help-popup.sh"

help_script="$ROOT_DIR/scripts/tmux-help-popup.sh"
if [[ -x "$help_script" ]]; then
  pass "tmux help popup script exists and is executable"
else
  fail "tmux help popup script exists and is executable"
fi

help_dump="$(TMUX_SOCKET="$SOCKET_NAME" "$help_script" --dump 2>/dev/null | rg -F 'tmux-help-popup.sh' || true)"
assert_contains "help popup dump includes a display-popup binding row" "$help_dump" "display-popup"
assert_contains "help popup dump includes tmux-help-popup.sh command path" "$help_dump" "tmux-help-popup.sh"

# Test 7: Flexoki palette and minimal statusline are applied.
status_style="$(tmux -L "$SOCKET_NAME" show-options -g status-style 2>/dev/null || true)"
assert_contains "status-style uses Flexoki dark background" "$status_style" "#100F0F"
assert_contains "status-style uses Flexoki text color" "$status_style" "#CECDC3"

status_justify="$(tmux -L "$SOCKET_NAME" show-options -g status-justify 2>/dev/null || true)"
assert_contains "window tabs are centered horizontally" "$status_justify" "centre"

pane_border_status="$(tmux -L "$SOCKET_NAME" show-options -g pane-border-status 2>/dev/null || true)"
assert_contains "pane border status text is disabled for minimal UI" "$pane_border_status" "off"

pane_border_style="$(tmux -L "$SOCKET_NAME" show-options -g pane-border-style 2>/dev/null || true)"
pane_active_border_style="$(tmux -L "$SOCKET_NAME" show-options -g pane-active-border-style 2>/dev/null || true)"
assert_contains "inactive pane border uses Flexoki ui color" "$pane_border_style" "#343331"
assert_contains "active pane border uses Flexoki blue accent" "$pane_active_border_style" "#4385BE"

status_left="$(tmux -L "$SOCKET_NAME" show-options -g status-left 2>/dev/null || true)"
status_right="$(tmux -L "$SOCKET_NAME" show-options -g status-right 2>/dev/null || true)"
assert_contains "status-left includes session name" "$status_left" "#S"
assert_contains "status-right includes useful mode flags" "$status_right" "client_prefix"
assert_contains "status-right includes current pane path" "$status_right" "pane_current_path"
assert_contains "status-right includes current time" "$status_right" "%H:%M"
assert_not_contains "status-right omits always-on command text for minimal UI" "$status_right" "pane_current_command"

plugin_lines="$(rg '^[[:space:]]*set -g @plugin ' "$CONFIG_PATH" 2>/dev/null || true)"
assert_contains "TPM plugin is present in config" "$plugin_lines" "tmux-plugins/tpm"
assert_contains "tmux-resurrect plugin is present in config" "$plugin_lines" "tmux-plugins/tmux-resurrect"
assert_contains "tmux-continuum plugin is present in config" "$plugin_lines" "tmux-plugins/tmux-continuum"
assert_contains "tmux-fzf plugin is present in config" "$plugin_lines" "sainnhe/tmux-fzf"
assert_contains "tmux-which-key plugin is present in config" "$plugin_lines" "alexwforsythe/tmux-which-key"
assert_contains "tmux-matryoshka plugin is present in config" "$plugin_lines" "niqodea/tmux-matryoshka"
assert_contains "tmux-thumbs plugin is present in config" "$plugin_lines" "fcsonline/tmux-thumbs"
assert_not_contains "dracula plugin is removed from tmux plugin config" "$plugin_lines" "dracula/tmux"
assert_not_contains "tmux-sensible plugin is removed to avoid hidden defaults" "$plugin_lines" "tmux-plugins/tmux-sensible"

tmux_which_key_autobuild="$(tmux -L "$SOCKET_NAME" show-options -gqv @tmux-which-key-disable-autobuild 2>/dev/null || true)"
assert_contains "tmux-which-key autobuild is disabled for lower startup overhead" "$tmux_which_key_autobuild" "1"

# Test 8: High-value navigation shortcuts are available.
choose_tree_binding="$(tmux -L "$SOCKET_NAME" list-keys -T root M-w 2>/dev/null || true)"
assert_contains "M-w opens choose-tree for fast session/window/pane switching" "$choose_tree_binding" "choose-tree -Zw"

find_window_binding="$(tmux -L "$SOCKET_NAME" list-keys -T root M-f 2>/dev/null || true)"
assert_contains "M-f opens prompt-driven window search" "$find_window_binding" "find-window"

tmux_fzf_order="$(tmux -L "$SOCKET_NAME" show-environment -g TMUX_FZF_ORDER 2>/dev/null || true)"
assert_contains "tmux-fzf order is scoped to high-signal actions" "$tmux_fzf_order" "session|window|pane|command|keybinding"

tmux_fzf_options="$(tmux -L "$SOCKET_NAME" show-environment -g TMUX_FZF_OPTIONS 2>/dev/null || true)"
assert_contains "tmux-fzf popup options are configured" "$tmux_fzf_options" "-p -w 70% -h 60% -m"

matryoshka_down="$(tmux -L "$SOCKET_NAME" show-options -gqv @matryoshka_down_keybind 2>/dev/null || true)"
assert_contains "matryoshka down keybind is configured" "$matryoshka_down" "M-d"
matryoshka_up="$(tmux -L "$SOCKET_NAME" show-options -gqv @matryoshka_up_keybind 2>/dev/null || true)"
assert_contains "matryoshka up keybind is configured" "$matryoshka_up" "M-u"
matryoshka_up_recursive="$(tmux -L "$SOCKET_NAME" show-options -gqv @matryoshka_up_recursive_keybind 2>/dev/null || true)"
assert_contains "matryoshka recursive up keybind is configured" "$matryoshka_up_recursive" "M-U"
matryoshka_inactive_style_strategy="$(tmux -L "$SOCKET_NAME" show-options -gqv @matryoshka_inactive_status_style_strategy 2>/dev/null || true)"
assert_contains "matryoshka inactive status style strategy is configured" "$matryoshka_inactive_style_strategy" "assignment"
matryoshka_inactive_style="$(tmux -L "$SOCKET_NAME" show-options -gqv @matryoshka_inactive_status_style 2>/dev/null || true)"
assert_contains "matryoshka inactive status style aligns with Flexoki palette" "$matryoshka_inactive_style" "bg=#282726,fg=#878580"

thumbs_key="$(tmux -L "$SOCKET_NAME" show-options -gqv @thumbs-key 2>/dev/null || true)"
assert_contains "tmux-thumbs key is configured to prefix+T" "$thumbs_key" "T"
thumbs_osc52="$(tmux -L "$SOCKET_NAME" show-options -gqv @thumbs-osc52 2>/dev/null || true)"
assert_contains "tmux-thumbs OSC52 clipboard integration is enabled" "$thumbs_osc52" "1"

bootstrap_script="$ROOT_DIR/scripts/tmux-plugin-bootstrap.sh"
if [[ -x "$bootstrap_script" ]]; then
  pass "plugin bootstrap script exists and is executable"
else
  fail "plugin bootstrap script exists and is executable"
fi

bootstrap_line="$(rg -F 'tmux-plugin-bootstrap.sh' "$CONFIG_PATH" 2>/dev/null || true)"
assert_contains "tmux config references plugin bootstrap script" "$bootstrap_line" "tmux-plugin-bootstrap.sh"
assert_contains "tmux config enables automatic plugin bootstrap mode" "$bootstrap_line" "--auto --quiet"

# Test 9: New numeric sessions are auto-renamed to codenames.
session_created_hook="$(tmux -L "$SOCKET_NAME" show-hooks -g session-created 2>/dev/null || true)"
assert_contains "session-created hook exists for codename auto-rename" "$session_created_hook" "hook_session_name"
assert_contains "session-created hook calls codename script" "$session_created_hook" "tmux-session-codename.sh"

tmux -L "$SOCKET_NAME" new-session -d >/dev/null 2>&1 || true
sleep 0.1
codename_session="$(tmux -L "$SOCKET_NAME" list-sessions -F '#S' 2>/dev/null | rg -v "^${SESSION_NAME}$" | head -n 1 || true)"
if [[ -n "$codename_session" && "$codename_session" =~ ^[a-z]+-[a-z]+-[0-9]{2}$ ]]; then
  pass "auto-created session gets a generated codename"
else
  printf '  Generated session name was: %s\n' "$codename_session"
  fail "auto-created session gets a generated codename"
fi

printf '\nSummary: %d passed, %d failed\n' "$pass_count" "$fail_count"
if (( fail_count > 0 )); then
  exit 1
fi
