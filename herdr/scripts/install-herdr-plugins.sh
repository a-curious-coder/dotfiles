#!/usr/bin/env bash
# Reinstalls this machine's herdr plugin set on a fresh machine. herdr has no
# declarative plugin config (config.toml only sets keybindings/UI for plugin
# actions) — plugins are installed imperatively via `herdr plugin install`,
# so this script just replays that. Pin refs so a plugin doesn't silently
# change behavior between machines; re-run `herdr plugin list` and update
# this file when you install/upgrade something.
set -euo pipefail

install() {
  herdr plugin install "$1" --ref "$2" -y
}

install mo-arvan/herdr-claude-auto-retry     5c43811e3fd94f33e271c3550a378ce2d4bb43c2
install mattyan1053/herdr-compose            008162eef69ca393ee329e57e5aed97ffbcfa554
install jlimas/herdr-worktree-seed           b2fb6aaa865c17580cd72bc6b66c674d86ef809d
install ezcorp-org/herdr-git-status          297744d68b8a6bced5b96eb56530487308ec6c7b
install ragamo/herdr-flock                   ae24844b3c8b1cf7cf3dfc3d6e6bc701b6e048a3
install wyattjoh/herdr-plugin-gh-pr          6fe22de9a90c569f2186595cfddc3707f55ba1bd
install JacquesvanWyk/herdr-keys             ecdfa459730bf757b9d017a511a9c64356d2969f
install AltanS/collie                        ded605c6d20e7d7732279cd9e90ebac095bb564b
install JanTvrdik/herdr-command-palette      eab940018c2135ac23718efa11e23e9dddcd2a75
install ntindle/herdr-resurrect              461e866cc772e156e39b94d085701972e24761af
install Numbered-com/herdr-ports             bada711cac11c2243600019446c8a68216415569
install StructuPath/herdr-guard              7327dc4f310987e05059a20cec7d8fc50bbf0cc5
install iurysza/herdr-tab-smart-rename       a580a9ef248357ea9d85cf0f2131acb2e3fae240
install tdi/herdr-worktree-setup             4527a11bd5444dbce34c3d4f459b49d704cc12a7
install iurysza/termscope                    cbc6da8103c263343b7082e27e804cc91312f944
install natori-hrj/herdr-triage              20e8f562656479b7ca70a6b95fa3f0bf6642de64
install alejodelosrios/herdr-claude-usage    67b13e892c851d8665303284d6259b4d939e48f9
install paulbkim-dev/vim-herdr-navigation    53e318c772c4d3b7fbd904ac43bcf3e5b5d8b244
install a-curious-coder/herdr-iris           04bdb5dc536ec6af83743e8e9e2ab958d77f063b

echo "Installed."
