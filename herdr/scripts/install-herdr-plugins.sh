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

# Regenerate the list below from the live install (keeps it from drifting):
#   jq -r '.[] | select(.source.kind=="github") | "install \(.source.owner)/\(.source.repo)\(if .source.subdir then "/"+.source.subdir else "" end) \(.source.resolved_commit)"' ~/.config/herdr/plugins.json | sort -f

install alexarthurs/herdr-sidebar/plugins/herdr-sidebar  d2fedf522079a0cca67e9aada8ab84e991ec1fcc
install aorumbayev/herdr-workflows                       6b876283e6c926db039b60cf75ebfa13274e439a
install chappse6/herdr-blueprint                         062bf6543107ef981e4f2399d0dce5889bd442b6
install ChmaraX/herdr-nvim                               e2ec32e7bbbb1eefd64363414b5806f84eedd6bc
install devswha/ovis                                     c3361acb771b28c29b5a6b02cf9a536d250b0510
install fullerzz/herdr-plugin-sesh                       0433c043301d126163a9e29b266a06f4648a5239
install furkankly/zoetrope/herdr-plugin                  b1f31dd26bd4e9e513885e39edb78d0850a5d1fe
install iurysza/termscope                                cbc6da8103c263343b7082e27e804cc91312f944
install JacquesvanWyk/herdr-keys                         ecdfa459730bf757b9d017a511a9c64356d2969f
install JanTvrdik/herdr-command-palette                  eab940018c2135ac23718efa11e23e9dddcd2a75
install kryptamine/herdr-auto-title                      d01fe9f8d453120d17f6ea37845def420bcced9e
install mattyan1053/herdr-compose                        008162eef69ca393ee329e57e5aed97ffbcfa554
install mo-arvan/herdr-claude-auto-retry                 5c43811e3fd94f33e271c3550a378ce2d4bb43c2
install natori-hrj/herdr-triage                          20e8f562656479b7ca70a6b95fa3f0bf6642de64
install nicosuave/memex                                  649355e4b442de9b63c24a3702f5c765233a84e4
install ntindle/herdr-resurrect                          461e866cc772e156e39b94d085701972e24761af
install Numbered-com/herdr-ports                         bada711cac11c2243600019446c8a68216415569
install paulbkim-dev/vim-herdr-navigation                820d48f5d9c9a7dece6a4bebfa3982ec30bbfbb7
install persiyanov/herdr-reviewr                         4c090225af706bf3aaa24b39fea890a72994f40f
install plannotator/herdr-annotate                       e3ca7e88ada0c77baf5714c006a5abe36798349c
install razajamil/herdr-plugin-workspace-manager         8302970a088b8dff4aca9a3d9034907d66be80a7
install robbyrussell/herdr-ohmyzsh                       bbc072ada531e6306276900a866a4b44a9b92e74
install StructuPath/herdr-guard                          7327dc4f310987e05059a20cec7d8fc50bbf0cc5
install tdi/herdr-worktree-setup                         c13ef573452b211b6097ddd0ce197be88e9a4b53
install uwuclxdy/clauth/herdr-plugin                     823b89a07f958ccb5055696eda73f07b6f59bb99
install wyattjoh/herdr-plugin-gh-pr                      6fe22de9a90c569f2186595cfddc3707f55ba1bd
install yankewei/herdr-focus-notify                      f931db5090ded54086e365dfb8db896c3a3e1a05
install zenbu-labs/terminal-browser/herdr-plugin         56337421b85e1ec01f340373dde85c7e1862f2a4

# Local plugins (own repos, linked not installed):
#   herdr plugin link ~/Projects/personal/herdr-iris
#   herdr plugin link ~/Projects/personal/herdr-plugin-manager

echo "Installed."
