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

## Kepano-aligned focus defaults

This config follows the constraints in `kepano-philosophy.md`: keep things legible, remove decorative UI, keep decisions low, and add plugins only when vanilla friction is real.

### Main GUI

- EPUB as default output format
- Manual device metadata management
- Duplicate checking enabled
- Search limited to key columns (`title`, `authors`, `tags`, `series`, `publisher`)
- Lean main table columns (`title`, `authors`, `rating`, `tags`)
- Hidden high-noise tag browser categories (`formats`, `identifiers`, `languages`, `publisher`, `series`)
- Confirm delete enabled
- Animations off, social metadata off
- Tray notifications off (`disable_tray_notification: true`)
- Update popups off (`new_version_notification: false`) to avoid interruption
- Check https://calibre-ebook.com/whats-new manually on a fixed cadence (for security fixes)
- Search-as-you-type and search highlight enabled
- Generic e-ink conversion profile
- Flexoki GUI palette:
  - `ui_style: calibre`
  - `color_palette: dark`
  - `dark_palette_name: Flexoki Dark`
  - `dark_palettes["Flexoki Dark"]` for app chrome (`#100f0f` bg, `#cecdc3` text, `#4385be` links)

### Reader

- `read_mode: flow` (continuous reading)
- `current_color_scheme: *Flexoki Dark`
- `override_book_colors: always` for consistency
- `fullscreen_when_opening: always` for immediate focus mode
- Hidden toolbar + hidden scrollbar
- Single viewer instance (`singleinstance: true`) to avoid window sprawl
- Typography tuned for long-form readability:
  - `base_font_size: 18`
  - `minimum_font_size: 10`
  - `max_text_width: 700`
  - `margin_left/right: 36`
  - `margin_top/bottom: 24`
  - `serif_family: Noto Serif`
- Read-aloud defaults:
  - `tts_bar_position: bottom-right`
  - `tts_backend.rate: 1.1`

Note: Calibre may rewrite `viewer-webengine.json` during normal use (window geometry, recent files, session state). If that happens, re-run `./calibre.sh` (or `./calibre.sh apply`).

To automatically restore reader settings after such rewrites, run `./calibre.sh apply`.

If Linux values still look wrong, run `./calibre.sh where` and compare:
- `CALIBRE_CONFIG_DIRECTORY`
- `CALIBRE_USE_SYSTEM_THEME` (must not be `1` if you want Calibre palette control)
- `Calibre runtime config dir`
- `~/.config/calibre/...` symlink targets

## ADHD/distraction rationale (research snapshot: 2026-02-17)

- WCAG visual presentation guidance recommends line width no more than 80 characters and generous spacing, which maps to tighter line width and larger text defaults in the viewer.
- WCAG text spacing guidance stresses preserving readability under increased spacing/size, so defaults here bias toward larger text and wider margins.
- CDC and ADDA guidance for ADHD accommodations emphasizes minimizing distractions and using lower-distraction environments, which maps to fullscreen-by-default, hidden reader chrome, and fewer UI notifications.
- Calibre manual confirms keyboard-first reading controls (`Ctrl+S` read aloud, `Ctrl+M` flow/paged toggle, `Ctrl+F11` toolbar toggle), so this setup assumes keyboard-first operation.

## Frictionless read-aloud flow

1. Open a book in the viewer (it will open in fullscreen).
2. Press `Ctrl+S` to open Read aloud.
3. Press `Space` to play/pause narration.
4. Click any word to jump narration to that point.
5. Use the read-aloud bar controls for speed/config if needed.

Notes:
- Default speech rate is set to `1.1`; your chosen voice is preserved.
- Read-aloud defaults are applied via `viewer-webengine.json` so they remain portable in this repo.

## Optional plugins (vanilla-first)

Only add plugins after a week of real friction. This keeps the setup aligned with Kepano constraints.

- `Action Chains` (v1.20.10, released 2025-03-16): bind one hotkey to a "focus ritual" chain (clear selection, open viewer, etc.).
- `Reading List` (v1.15.7, released 2026-02-09): maintain a constrained "Now/Next" queue to reduce choice overload.
- `Count Pages` (v1.14.6, released 2026-02-09): estimate reading size/time so sessions feel bounded.
- `Find Duplicates` (v1.10.10, released 2026-02-09): keep library clean to reduce metadata clutter.
- `Backup Configuration Folder` (v1.1.2, released 2025-02-08): safety net for settings experiments.

Install path: `Preferences -> Advanced -> Plugins`.

Reference indexes:
- https://plugins.calibre-ebook.com/
- https://plugins.calibre-ebook.com/stats.html

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

## Source links

- https://manual.calibre-ebook.com/viewer.html
- https://manual.calibre-ebook.com/gui.html
- https://manual.calibre-ebook.com/customize.html#customizing-calibre-with-plugins
- https://calibre-ebook.com/whats-new
- https://www.w3.org/WAI/WCAG21/Understanding/visual-presentation.html
- https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html
- https://www.cdc.gov/adhd/treatment/classroom.html
- https://add.org/recommended-accommodations-college-students-adhd/
