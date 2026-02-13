# Calibre Dotfiles

This repo includes two platform-specific stow packages for Calibre config:

- `calibre-macos` -> `~/Library/Preferences/calibre`
- `calibre-linux` -> `~/.config/calibre`

Use the helper script to pick the correct package automatically:

```bash
./calibre.sh stow
```

Re-apply reader settings idempotently (useful after Calibre runtime rewrites):

```bash
./calibre.sh apply
```

Run a health check (symlinks + expected key values):

```bash
./calibre.sh check
```

Show active runtime config path + loaded values (best for Linux verification):

```bash
./calibre.sh where
```

One-command workflow (stow + apply + check):

```bash
./calibre.sh
```

Or stow manually:

```bash
# macOS
stow calibre-macos

# Linux
stow calibre-linux
```

## Steph-style conventions applied

- EPUB as default output format
- Manual device metadata management
- Duplicate checking enabled
- Search limited to key columns (`title`, `authors`, `tags`, `series`, `publisher`)
- Lean main table columns (`title`, `authors`, `rating`, `tags`, `pubdate`)
- Confirm delete enabled
- Animations off, social metadata off
- Search-as-you-type and search highlight enabled
- Generic e-ink conversion profile
- Main GUI defaults:
  - `ui_style: calibre`
  - `color_palette: dark`
  - `dark_palette_name: Flexoki Dark`
  - Custom `dark_palettes["Flexoki Dark"]` applied for app chrome (`#100f0f` bg, `#cecdc3` text, `#4385be` links)
- Reader defaults:
  - `read_mode: flow` (continuous/infinite scrolling)
  - `current_color_scheme: *Flexoki Dark` (custom scheme: `#100f0f` bg, `#cecdc3` fg, `#4385be` links)
  - `override_book_colors: always` for consistent appearance
  - `fullscreen_when_opening: always` for immediate focus mode
  - `tts_bar_position: bottom-right` to keep read-aloud controls visible but out of the text lane
  - `tts_backend.rate: 1.1` for slightly faster default narration pace
  - `standalone_font_settings.serif_family: Noto Serif`
  - Hidden reader action toolbar for reduced UI chrome
  - Capped line width (`max_text_width: 760`) for readable prose

Note: Calibre may rewrite `viewer-webengine.json` during normal use (window geometry, recent files, session state). If that happens, re-run `./calibre.sh` (or `./calibre.sh apply`).

To automatically restore reader settings after such rewrites, run `./calibre.sh apply`.

If Linux values still look wrong, run `./calibre.sh where` and compare:
- `CALIBRE_CONFIG_DIRECTORY`
- `CALIBRE_USE_SYSTEM_THEME` (must not be `1` if you want Calibre palette control)
- `Calibre runtime config dir`
- `~/.config/calibre/...` symlink targets

## Frictionless read-aloud flow

1. Open a book in the viewer (it will open in fullscreen).
2. Press `Ctrl+S` to open Read aloud.
3. Press `Space` to play/pause narration.
4. Click any word to jump narration to that point.
5. Use the read-aloud bar controls for speed/config if needed.

Notes:
- Default speech rate is set to `1.1`; your chosen voice is preserved.
- Read-aloud defaults are applied via `viewer-webengine.json` so they remain portable in this repo.

## Noto Serif install

Install via your setup scripts:

- macOS: `./install-modern-tools.sh` (installs `font-noto-serif` via Homebrew cask)
- Ubuntu: `./install-modern-tools.sh` (installs `fonts-noto-core`)

## 1-7 rating scale

Calibre's default rating field is star-based. To match the 1-7 convention, create a custom integer column in Calibre UI:

1. Open `Preferences` -> `Add your own columns`
2. Create an `Integer` column
3. Suggested lookup name: `#rating7`
4. Suggested heading: `Rating (1-7)`
