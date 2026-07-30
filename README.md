<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/header/graph.svg?title=dotfiles&subtitle=Plain-text+configs+for+Hyprland%2C+Neovim+and+zsh%2C+managed+with+GNU+Stow&logo=archlinux&align=left&mode=dark" />
    <img alt="dotfiles" src="https://shieldcn.dev/header/graph.svg?title=dotfiles&subtitle=Plain-text+configs+for+Hyprland%2C+Neovim+and+zsh%2C+managed+with+GNU+Stow&logo=archlinux&align=left&mode=light" />
  </picture>
</p>

<p align="center">
  <a href="https://github.com/a-curious-coder/dotfiles/actions/workflows/quick-checks.yml"><img alt="CI status" src="https://shieldcn.dev/github/ci/a-curious-coder/dotfiles.svg?workflow=quick-checks.yml&branch=main&variant=secondary" /></a>
  <a href="https://github.com/a-curious-coder/dotfiles/commits/main"><img alt="Last commit" src="https://shieldcn.dev/github/last-commit/a-curious-coder/dotfiles.svg?variant=secondary" /></a>
  <a href="LICENSE"><img alt="License" src="https://shieldcn.dev/github/license/a-curious-coder/dotfiles.svg?variant=secondary" /></a>
  <img alt="Managed with GNU Stow" src="https://shieldcn.dev/badge/managed%20with-GNU%20Stow.svg?variant=secondary&logo=gnu" />
</p>

Personal configurations managed with GNU Stow. Plain text, portable,
version-controlled.

## Quick start

```bash
git clone git@github.com:a-curious-coder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh            # tools + stow + tmux plugins
```

Stow packages by hand instead:

```bash
# Everyday
stow zsh starship tmux nvim ghostty btop lazygit lazydocker fastfetch ripgrep

# Hyprland desktop
stow hypr kanshi waybar rofi swaync wlogout calibre-linux
```

Remove a package with `stow -D <package>`.

Full install options live in [SETUP.md](SETUP.md); day-to-day commands in
[docs/operations.md](docs/operations.md).

## Philosophy

Configs follow [Kepano's principles](kepano-philosophy.md): file over app,
radical minimalism, reduced friction, intentional constraints, clarity over
cleverness. Prefer deletion over addition; add abstraction only when it removes
real duplication.

Style and decision guidance lives in [style-guide.md](style-guide.md).

## Structure

Each directory below is a stow package — `stow <package>` symlinks it into
`$HOME`.

```
dotfiles/
├── btop/               Resource monitor
├── calibre-linux/      Calibre config (~/.config/calibre)
├── claude/             Global Claude Code preferences (~/.claude)
├── direnv/             direnv config
├── fastfetch/          System info
├── ghostty/            Terminal emulator
├── herdr/              Herdr TUI config + user service
├── hypr/               Hyprland compositor
├── kanshi/             Wayland display profiles
├── lazydocker/         Docker TUI
├── lazygit/            Git TUI
├── nvim/               Neovim
├── ripgrep/            ripgrep config
├── rofi/               Application launcher
├── starship/           Shell prompt
├── swaync/             Notification centre
├── tmux/               Terminal multiplexer
├── voxtype/            Voxtype dictation config
├── waybar/             Status bar
├── wlogout/            Logout menu
├── yazi/               Terminal file manager
└── zsh/                Shell config, aliases, functions
```

Not stow packages:

| Path | Contents |
|------|----------|
| `bin/` | Standalone utilities (`cloak.py`) |
| `docs/` | Repo docs (operations, Calibre, refinement checklist) |
| `scripts/` | Repo maintenance (`doctor.sh`, `check-shell.sh`) |
| `transcription-stack/` | Offline dictation daemon — see its own [README](transcription-stack/README.md) |

## Scripts

| File | Purpose |
|------|---------|
| `bootstrap.sh` | Install + stow + tmux bootstrap in one command |
| `install-modern-tools.sh` | Install CLI tools (glow, mise, dust, navi, posting, …) |
| `setup-tmux.sh` | Stow tmux config, install/update TPM and plugins |
| `calibre.sh` | Calibre entrypoint (`stow`, `apply`, `check`, `where`, `all`) |
| `detect-platform.sh` | Platform detection used by the setup scripts |
| `ubuntu_install.sh` | Wrapper that delegates to `install-modern-tools.sh` |
| `scripts/doctor.sh` | Run the repo health checks |
| `scripts/check-shell.sh` | `shellcheck` the maintained shell scripts |
| `scripts/check-stow-targets.sh` | Assert every package installs only dot-prefixed paths |

## Neovim

Requires Neovim >= 0.11, Node.js, ripgrep, fd, and a Nerd Font.

- Keymaps: find/search on `<leader>f*`, UI toggles on `<leader>u*`
- Markdown: `gf` follows `[[wikilinks]]` (including `[[note#heading]]`)
- Markdown reading: `<leader>um` read view, `<leader>uM` split preview
- Terminal: `<leader>tt` toggles a floating terminal
- Telescope: repo-scoped pickers by default, toggle with `<leader>fT`

## direnv

zsh initialises `direnv` after `zoxide`, so project `.envrc` files load on `cd`.
Run `direnv allow` once per project after creating or changing an `.envrc`.

## License

[MIT](LICENSE)
