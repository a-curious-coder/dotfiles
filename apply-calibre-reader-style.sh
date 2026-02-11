#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

os_name="$(uname -s)"
case "$os_name" in
  Darwin)
    config_dir="$HOME/Library/Preferences/calibre"
    ;;
  Linux)
    config_dir="$HOME/.config/calibre"
    ;;
  *)
    echo "Unsupported OS: $os_name" >&2
    exit 1
    ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for this script" >&2
  exit 1
fi

mkdir -p "$config_dir"
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
  | .session_data.current_color_scheme = "sepia-light"
  | .session_data.hide_tooltips = true
  | .session_data.margin_top = 20
  | .session_data.margin_right = 24
  | .session_data.margin_bottom = 20
  | .session_data.margin_left = 24
  | .session_data.max_text_width = 760
  | .session_data.override_book_colors = "always"
  | .session_data.read_mode = "flow"
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

# Preserve symlinked targets by writing in place rather than mv over path.
cat "$tmp_file" > "$viewer_cfg"
rm -f "$tmp_file"

echo "Applied reader style to: $viewer_cfg"
jq -r '.session_data.read_mode, .session_data.current_color_scheme, .session_data.override_book_colors, .session_data.standalone_font_settings.serif_family' "$viewer_cfg"
