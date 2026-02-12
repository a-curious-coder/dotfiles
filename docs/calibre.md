# Calibre Dotfiles

This repo includes two platform-specific stow packages for Calibre config:

- `calibre-macos` -> `~/Library/Preferences/calibre`
- `calibre-linux` -> `~/.config/calibre`

Use the helper script to pick the correct package automatically:

```bash
./stow-calibre.sh
```

Re-apply reader settings idempotently (useful after Calibre runtime rewrites):

```bash
./apply-calibre-reader-style.sh
```

Run a health check (symlinks + expected key values):

```bash
./calibre-check.sh
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
- Reader defaults:
  - `read_mode: flow` (continuous/infinite scrolling)
  - `current_color_scheme: sepia-light`
  - `override_book_colors: always` for consistent appearance
  - `standalone_font_settings.serif_family: Noto Serif`
  - Hidden reader action toolbar for reduced UI chrome
  - Capped line width (`max_text_width: 760`) for readable prose

Note: Calibre may rewrite `viewer-webengine.json` during normal use (window geometry, recent files, session state). If that happens, re-run `./stow-calibre.sh` or manually re-apply reader settings.

To automatically restore reader settings after such rewrites, run `./apply-calibre-reader-style.sh`.

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
