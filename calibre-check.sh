#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for this script" >&2
  exit 1
fi

realpath_compat() {
  perl -MCwd=realpath -e 'print realpath($ARGV[0])' "$1"
}

os_name="$(uname -s)"
case "$os_name" in
  Darwin)
    config_dir="$HOME/Library/Preferences/calibre"
    package_dir="$repo_root/calibre-macos/Library/Preferences/calibre"
    ;;
  Linux)
    config_dir="$HOME/.config/calibre"
    package_dir="$repo_root/calibre-linux/.config/calibre"
    ;;
  *)
    echo "Unsupported OS: $os_name" >&2
    exit 1
    ;;
esac

failures=0
warnings=0

pass() { printf 'PASS: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }

check_symlink_required() {
  local rel="$1"
  local target="$config_dir/$rel"
  local expected="$package_dir/$rel"

  if [ ! -e "$target" ]; then
    fail "$rel missing at $target"
    return
  fi

  if [ ! -L "$target" ]; then
    warn "$rel is not a symlink (Calibre may rewrite this file during runtime)"
    return
  fi

  local resolved_target resolved_expected
  resolved_target="$(realpath_compat "$target")"
  resolved_expected="$(realpath_compat "$expected")"
  if [ "$resolved_target" = "$resolved_expected" ]; then
    pass "$rel symlink points to stow package"
  else
    warn "$rel symlink target mismatch ($resolved_target != $resolved_expected)"
  fi
}

check_symlink_optional() {
  local rel="$1"
  local target="$config_dir/$rel"
  local expected="$package_dir/$rel"

  if [ ! -e "$target" ]; then
    fail "$rel missing at $target"
    return
  fi

  if [ -L "$target" ]; then
    local resolved_target resolved_expected
    resolved_target="$(realpath_compat "$target")"
    resolved_expected="$(realpath_compat "$expected")"
    if [ "$resolved_target" = "$resolved_expected" ]; then
      pass "$rel symlink points to stow package"
    else
      warn "$rel symlink target mismatch ($resolved_target != $resolved_expected)"
    fi
  else
    warn "$rel is not a symlink (Calibre may rewrite this file during runtime)"
  fi
}

check_json_eq() {
  local file="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(jq -r "$key" "$file" 2>/dev/null || true)"
  if [ "$actual" = "$expected" ]; then
    pass "$(basename "$file"): $key == $expected"
  else
    fail "$(basename "$file"): $key == $actual (expected $expected)"
  fi
}

check_page_setup_profile() {
  local file="$1"
  local expected="$2"
  local payload actual
  payload="$(sed -e '1s/^json://' "$file" 2>/dev/null || true)"
  actual="$(printf '%s' "$payload" | jq -r '.output_profile' 2>/dev/null || true)"
  if [ "$actual" = "$expected" ]; then
    pass "$(basename "$file"): .output_profile == $expected"
  else
    fail "$(basename "$file"): .output_profile == $actual (expected $expected)"
  fi
}

check_symlink_required "global.py.json"
check_symlink_required "gui.json"
check_symlink_required "gui.py.json"
check_symlink_required "conversion/page_setup.py"
check_symlink_optional "viewer-webengine.json"

check_json_eq "$config_dir/global.py.json" '.output_format' 'epub'
check_json_eq "$config_dir/global.py.json" '.add_formats_to_existing' 'true'
check_json_eq "$config_dir/global.py.json" '.check_for_dupes_on_ctl' 'true'
check_json_eq "$config_dir/global.py.json" '.limit_search_columns' 'true'

check_json_eq "$config_dir/gui.py.json" '.confirm_delete' 'true'
check_json_eq "$config_dir/gui.py.json" '.disable_animations' 'true'
check_json_eq "$config_dir/gui.py.json" '.get_social_metadata' 'false'
check_json_eq "$config_dir/gui.py.json" '.search_as_you_type' 'true'
check_json_eq "$config_dir/gui.py.json" '.highlight_search_matches' 'true'
check_json_eq "$config_dir/gui.py.json" '.upload_news_to_device' 'false'

check_page_setup_profile "$config_dir/conversion/page_setup.py" 'generic_eink'

check_json_eq "$config_dir/viewer-webengine.json" '.session_data.read_mode' 'flow'
check_json_eq "$config_dir/viewer-webengine.json" '.session_data.current_color_scheme' 'sepia-light'
check_json_eq "$config_dir/viewer-webengine.json" '.session_data.override_book_colors' 'always'
check_json_eq "$config_dir/viewer-webengine.json" '.session_data.standalone_font_settings.serif_family' 'Noto Serif'
check_json_eq "$config_dir/viewer-webengine.json" '.session_data.standalone_misc_settings.show_actions_toolbar' 'false'

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if [ "$failures" -gt 0 ]; then
  echo "Suggested fixes: ./stow-calibre.sh && ./apply-calibre-reader-style.sh"
  exit 1
fi

echo "Calibre config check passed"
