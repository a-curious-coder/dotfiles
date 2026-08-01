# Raycast script commands

## quick-capture.sh

Fires `obsidian://quick-capture`, which the
[Quickdraw](https://github.com/callummclennan/obsidian-quickdraw) Obsidian
plugin (not tracked in this repo) picks up: shrinks the main Obsidian window
into a small popup in the corner, runs your configured capture command (a
QuickAdd choice) in a new tab, and snaps the window back on a second trigger
(or `Cmd`/`Ctrl`+`Enter`).

Prereqs (installed in the Obsidian vault, not tracked here):
- [QuickAdd](https://github.com/chhoumann/quickadd) plugin, with a choice
  registered as an Obsidian command (enable "Add as command" on the choice)
- [Quickdraw](https://github.com/callummclennan/obsidian-quickdraw) plugin
  installed and enabled, with Settings → "Command to run on open" set to that
  QuickAdd choice's command ID (`quickadd:choice:<uuid>`, found in
  `<vault>/.obsidian/plugins/quickadd/data.json`)

Setup on a new machine:
1. Point Raycast's Script Directories (Extensions settings) at this folder,
   or symlink this script into wherever your launcher scans.
2. Assign a hotkey to "Quick Capture Note" in Raycast preferences.

No vault name or command ID needed in this script — the plugin's protocol
handler runs inside whichever vault currently has it loaded.
