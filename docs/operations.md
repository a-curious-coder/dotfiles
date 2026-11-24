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
stow git zsh starship nvim ghostty claude direnv herdr yazi
```

## Stow Linux desktop packages

```bash
stow hypr kanshi waybar rofi swaync wlogout
```

## Stow macOS-only packages

```bash
stow llama opencode
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
