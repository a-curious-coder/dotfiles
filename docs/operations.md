# Operations

High-signal commands for common repo tasks.

## Jump to the repo

```bash
z dotfiles
```

## Bootstrap a new machine

```bash
./bootstrap.sh
```

## Stow common packages

```bash
stow git zsh starship tmux nvim ghostty espanso
```

## Stow macOS packages

```bash
stow aerospace sketchybar hammerspoon calibre-macos
```

## Stow Linux desktop packages

```bash
stow hypr waybar rofi ags swaync wlogout calibre-linux
```

## Set up tmux plugins

```bash
./setup-tmux.sh
```

## Link Espanso on macOS

```bash
./scripts/setup-espanso-macos.sh
```

## Run repo checks

```bash
./scripts/doctor.sh
```

## Dry-run a stow operation

```bash
stow -nvt "$HOME" <package>
```

## Remove a package

```bash
stow -D <package>
```
