#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

os_name="$(uname -s)"
case "$os_name" in
  Darwin)
    package="calibre-macos"
    config_dir="$HOME/Library/Preferences/calibre"
    ;;
  Linux)
    package="calibre-linux"
    config_dir="$HOME/.config/calibre"
    ;;
  *)
    echo "Unsupported OS: $os_name" >&2
    exit 1
    ;;
esac

package_dir="$repo_root/$package/${config_dir#"$HOME/"}"

usage() {
  cat <<'EOF'
Usage: ./calibre.sh <command>

Commands:
  stow   Stow the platform-specific Calibre package
  apply  Re-apply reader/read-aloud style defaults
  check  Validate symlinks and key settings
  where  Show active config directory and loaded runtime values
  all    Run stow, apply, then check
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for this command" >&2
    exit 1
  fi
}

realpath_compat() {
  perl -MCwd=realpath -e 'print realpath($ARGV[0])' "$1"
}

run_stow() {
  mkdir -p "$config_dir"

  timestamp="$(date +%Y%m%d_%H%M%S)"
  backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-calibre-backup/$timestamp"
  moved_existing=0

  while IFS= read -r src_file; do
    rel_path="${src_file#"$package/"}"
    target_path="$HOME/$rel_path"

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
      mkdir -p "$backup_root/$(dirname "$rel_path")"
      mv "$target_path" "$backup_root/$rel_path"
      moved_existing=1
    fi
  done < <(find "$package" -type f | sort)

  stow "$package"

  echo "Stowed package '$package'."
  echo "Calibre config location: $config_dir"
  if [ "$moved_existing" -eq 1 ]; then
    echo "Backed up previous files to: $backup_root"
  fi
  echo "Note: Create a custom integer column in Calibre for 1-7 ratings (e.g. #rating7)."
}

run_apply() {
  require_jq

  mkdir -p "$config_dir"

  gui_cfg="$config_dir/gui.json"
  if [ ! -s "$gui_cfg" ]; then
    printf '{}\n' > "$gui_cfg"
  fi

  gui_tmp_file="$(mktemp)"
  jq '
    .ui_style = "calibre"
    | .color_palette = "dark"
    | .dark_palette_name = "Flexoki Dark"
    | .dark_palettes = ((.dark_palettes // {}) + {
        "Flexoki Dark": {
          "Window": "#100f0f",
          "WindowText": "#cecdc3",
          "WindowText-disabled": "#878580",
          "Base": "#1c1b1a",
          "Text": "#cecdc3",
          "Text-disabled": "#878580",
          "Button": "#1c1b1a",
          "ButtonText": "#cecdc3",
          "ButtonText-disabled": "#878580",
          "PlaceholderText": "#878580",
          "ToolTipBase": "#1c1b1a",
          "ToolTipText": "#cecdc3",
          "BrightText": "#d14d41",
          "Highlight": "#205ea6",
          "HighlightedText": "#f2f0e5",
          "HighlightedText-disabled": "#878580",
          "Link": "#4385be",
          "LinkVisited": "#8b7ec8",
          "AlternateBase": "#282726"
        }
      })
    | .quick_start_guide_added = true
    | .cover_grid_background = (.cover_grid_background // {
        "dark": [45, 45, 45],
        "dark_texture": null,
        "light": [80, 80, 80],
        "light_texture": null,
        "migrated": true
      })
  ' "$gui_cfg" > "$gui_tmp_file"

  cat "$gui_tmp_file" > "$gui_cfg"
  rm -f "$gui_tmp_file"

  viewer_cfg="$config_dir/viewer-webengine.json"
  if [ ! -s "$viewer_cfg" ]; then
    printf '{}\n' > "$viewer_cfg"
  fi

  tmp_file="$(mktemp)"
  jq '
    .old_prefs_migrated = true
    | .session_data = (.session_data // {})
    | .session_data.base_font_size = 16
    | .session_data.book_scrollbar = false
    | .session_data.user_color_schemes = ((.session_data.user_color_schemes // {}) + {
        "*Flexoki Dark": {
          "name": "Flexoki Dark",
          "foreground": "#cecdc3",
          "background": "#100f0f",
          "link": "#4385be"
        }
      })
    | .session_data.current_color_scheme = "*Flexoki Dark"
    | .session_data.fullscreen_when_opening = "always"
    | .session_data.hide_tooltips = true
    | .session_data.margin_top = 20
    | .session_data.margin_right = 24
    | .session_data.margin_bottom = 20
    | .session_data.margin_left = 24
    | .session_data.max_text_width = 760
    | .session_data.override_book_colors = "always"
    | .session_data.read_mode = "flow"
    | .session_data.tts_bar_position = "bottom-right"
    | .session_data.tts_backend = ((.session_data.tts_backend // {}) + {
        "rate": 1.1
      })
    | .session_data.standalone_font_settings = ((.session_data.standalone_font_settings // {}) + {
        "minimum_font_size": 8,
        "serif_family": "Noto Serif",
        "standard_font": "serif",
        "zoom_step_size": 20
      })
    | .session_data.standalone_misc_settings = ((.session_data.standalone_misc_settings // {}) + {
        "auto_hide_mouse": true,
        "remember_last_read": true,
        "remember_window_geometry": false,
        "restore_docks": true,
        "save_annotations_in_ebook": true,
        "show_actions_toolbar": false,
        "show_actions_toolbar_in_fullscreen": false,
        "singleinstance": false
      })
  ' "$viewer_cfg" > "$tmp_file"

  # Write in place so this works whether the target is symlinked or rewritten by Calibre.
  cat "$tmp_file" > "$viewer_cfg"
  rm -f "$tmp_file"

  echo "Applied reader style to: $viewer_cfg"
}

run_where() {
  echo "OS: $os_name"
  echo "Dotfiles package: $package"
  echo "Default config dir: $config_dir"
  echo "CALIBRE_CONFIG_DIRECTORY: ${CALIBRE_CONFIG_DIRECTORY:-<unset>}"
  echo "CALIBRE_USE_SYSTEM_THEME: ${CALIBRE_USE_SYSTEM_THEME:-<unset>}"
  if [ "${CALIBRE_USE_SYSTEM_THEME:-0}" = "1" ]; then
    echo "WARNING: CALIBRE_USE_SYSTEM_THEME=1 forces system theme and can ignore gui.json palette settings."
  fi

  active_dir="$config_dir"
  if command -v calibre-debug >/dev/null 2>&1; then
    active_dir="$(calibre-debug -c "from calibre.constants import config_dir; print(config_dir)" 2>/dev/null | tail -n1 || true)"
    if [ -z "$active_dir" ]; then
      active_dir="$config_dir"
    fi
    echo "Calibre runtime config dir: $active_dir"
  else
    echo "Calibre runtime config dir: <calibre-debug not found>"
  fi

  if [ "$active_dir" != "$config_dir" ]; then
    echo "WARNING: Runtime config differs from default path above."
  fi

  echo
  echo "Tracked files:"
  files=(global.py.json gui.py.json gui.json conversion/page_setup.py viewer-webengine.json)
  for rel in "${files[@]}"; do
    path="$config_dir/$rel"
    if [ -e "$path" ] || [ -L "$path" ]; then
      if [ -L "$path" ]; then
        printf '  %s -> %s\n' "$path" "$(readlink -f "$path")"
      else
        printf '  %s (regular file)\n' "$path"
      fi
    else
      printf '  %s (missing)\n' "$path"
    fi
  done

  viewer_cfg="$config_dir/viewer-webengine.json"
  gui_cfg="$config_dir/gui.json"
  if [ -f "$gui_cfg" ] && command -v jq >/dev/null 2>&1; then
    echo
    echo "gui.json values:"
    jq -r '
      "  ui_style=\(.ui_style // "<unset>")"
      , "  color_palette=\(.color_palette // "<unset>")"
      , "  dark_palette_name=\(.dark_palette_name // "<unset>")"
      , "  dark_palettes[Flexoki Dark].Window=\(.dark_palettes["Flexoki Dark"].Window // "<unset>")"
      , "  dark_palettes[Flexoki Dark].Text=\(.dark_palettes["Flexoki Dark"].Text // "<unset>")"
      , "  dark_palettes[Flexoki Dark].Link=\(.dark_palettes["Flexoki Dark"].Link // "<unset>")"
    ' "$gui_cfg"
  fi

  if [ -f "$viewer_cfg" ] && command -v jq >/dev/null 2>&1; then
    echo
    echo "viewer-webengine.json values:"
    jq -r '
      .session_data as $sd
      | "  read_mode=\($sd.read_mode // "<unset>")"
      , "  current_color_scheme=\($sd.current_color_scheme // "<unset>")"
      , "  fullscreen_when_opening=\($sd.fullscreen_when_opening // "<unset>")"
      , "  tts_bar_position=\($sd.tts_bar_position // "<unset>")"
      , "  tts_backend.rate=\($sd.tts_backend.rate // "<unset>")"
    ' "$viewer_cfg"
  fi

  if command -v calibre-debug >/dev/null 2>&1; then
    echo
    echo "Calibre runtime GUI values:"
    calibre-debug -c "from calibre.utils.config import JSONConfig; g=JSONConfig('gui'); dp=(g.get('dark_palettes') or {}).get('Flexoki Dark', {}); print('  ui_style='+str(g.get('ui_style','<unset>'))); print('  color_palette='+str(g.get('color_palette','<unset>'))); print('  dark_palette_name='+str(g.get('dark_palette_name','<unset>'))); print('  dark_palettes[Flexoki Dark].Window='+str(dp.get('Window','<unset>'))); print('  dark_palettes[Flexoki Dark].Text='+str(dp.get('Text','<unset>'))); print('  dark_palettes[Flexoki Dark].Link='+str(dp.get('Link','<unset>')))"

    echo
    echo "Calibre runtime session values:"
    calibre-debug -c "from calibre.utils.config import JSONConfig; sd=(JSONConfig('viewer-webengine').get('session_data') or {}); tb=(sd.get('tts_backend') or {}); print('  read_mode='+str(sd.get('read_mode','<unset>'))); print('  current_color_scheme='+str(sd.get('current_color_scheme','<unset>'))); print('  fullscreen_when_opening='+str(sd.get('fullscreen_when_opening','<unset>'))); print('  tts_bar_position='+str(sd.get('tts_bar_position','<unset>'))); print('  tts_backend.rate='+str(tb.get('rate','<unset>')))"
  fi
}

run_check() {
  require_jq

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

  check_json_eq "$config_dir/gui.json" '.ui_style' 'calibre'
  check_json_eq "$config_dir/gui.json" '.color_palette' 'dark'
  check_json_eq "$config_dir/gui.json" '.dark_palette_name' 'Flexoki Dark'
  check_json_eq "$config_dir/gui.json" '.dark_palettes["Flexoki Dark"].Window' '#100f0f'
  check_json_eq "$config_dir/gui.json" '.dark_palettes["Flexoki Dark"].Text' '#cecdc3'
  check_json_eq "$config_dir/gui.json" '.dark_palettes["Flexoki Dark"].Link' '#4385be'

  check_page_setup_profile "$config_dir/conversion/page_setup.py" 'generic_eink'

  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.read_mode' 'flow'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.current_color_scheme' '*Flexoki Dark'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.user_color_schemes["*Flexoki Dark"].background' '#100f0f'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.user_color_schemes["*Flexoki Dark"].foreground' '#cecdc3'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.user_color_schemes["*Flexoki Dark"].link' '#4385be'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.override_book_colors' 'always'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.fullscreen_when_opening' 'always'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.tts_bar_position' 'bottom-right'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.tts_backend.rate' '1.1'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.standalone_font_settings.serif_family' 'Noto Serif'
  check_json_eq "$config_dir/viewer-webengine.json" '.session_data.standalone_misc_settings.show_actions_toolbar' 'false'

  if [ "${CALIBRE_USE_SYSTEM_THEME:-0}" = "1" ]; then
    warn "CALIBRE_USE_SYSTEM_THEME=1 can override Calibre GUI palette; set it to 0/unset for Flexoki Dark GUI."
  fi

  printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
  if [ "$failures" -gt 0 ]; then
    echo "Suggested fix: ./calibre.sh all"
    exit 1
  fi

  echo "Calibre config check passed"
}

command="${1:-all}"
case "$command" in
  stow)
    run_stow
    ;;
  apply)
    run_apply
    ;;
  check)
    run_check
    ;;
  where)
    run_where
    ;;
  all)
    run_stow
    run_apply
    run_check
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 1
    ;;
esac
