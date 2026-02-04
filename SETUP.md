# Dotfiles Setup Guide

This guide covers the new configurations for zoxide cd aliasing, minimalist prompt, and Ghostty themes.

## 🔧 Installation

### Using GNU Stow

```bash
cd ~/Projects/dotfiles

# Install zsh configuration
stow zsh

# Install starship configuration
stow starship

# Install Ghostty configuration
stow ghostty

# Install SketchyBar configuration (macOS)
stow sketchybar
```

### Manual Installation

```bash
# Link zsh config
ln -sf ~/Projects/dotfiles/zsh/.zshrc ~/.zshrc

# Link starship config
mkdir -p ~/.config
ln -sf ~/Projects/dotfiles/starship/starship.toml ~/.config/starship.toml

# Link Ghostty config
mkdir -p ~/.config/ghostty/themes
ln -sf ~/Projects/dotfiles/ghostty/config ~/.config/ghostty/config
ln -sf ~/Projects/dotfiles/ghostty/themes/* ~/.config/ghostty/themes/
```

## 📦 Features

### 1. Zoxide CD Alias

The `cd` command now uses zoxide for smart directory navigation:

```bash
# Works like normal cd, but smarter
cd projects          # Jump to ~/Projects even from anywhere
cd ..                # Still works
cd -                 # Still works (go back)

# If you use unsupported flags:
cd -P /some/path     # Shows helpful error message
# ⚠️  cd is aliased to zoxide. Use 'z' for zoxide or 'builtin cd' for native cd.

# Use native cd if needed:
builtin cd /some/path
```

**How it helps AI tools**: When AI tools try to use `cd` with incompatible flags, they'll see a clear message explaining that `cd` is aliased to zoxide.

### 2. Minimalist Prompt Styles

Three ultra-minimal prompt styles available:

**Lambda (λ)** - Programmer aesthetic
```
λ your command
```

**Zen (·)** - Ultra minimal
```
· your command
```

**Context-Aware** - Smart minimalism
```
λ your command         # Local
user@host λ your command   # SSH
```

#### Switching Prompt Styles

```bash
# List available styles
prompt-style

# Switch to lambda
prompt-style lambda

# Switch to zen
prompt-style zen

# Switch to context-aware
prompt-style context

# Reload shell
source ~/.zshrc
```

### 3. Ghostty Themes

Four themes are available:
- **current**: Your existing color scheme (Catppuccin-style)
- **minimalist**: Clean, light theme for focused work
- **dracula**: Popular vibrant dark theme
- **nord**: Arctic-inspired cool color palette

#### Switching Themes

```bash
# List available themes
ghostty-theme

# Switch to a theme
ghostty-theme dracula
ghostty-theme minimalist
ghostty-theme nord
ghostty-theme current

# Restart Ghostty or open a new window to see changes
```

#### Manual Theme Switching

Edit `~/.config/ghostty/config` and change the import line:

```conf
# Comment out current theme
# import = ~/.config/ghostty/themes/theme-current.conf

# Uncomment desired theme
import = ~/.config/ghostty/themes/theme-dracula.conf
```

## 🚀 Apply Changes

After installing, reload your shell:

```bash
# Reload zsh configuration
source ~/.zshrc

# Or simply open a new terminal
```

### 4. SketchyBar (macOS)

```bash
# Install SketchyBar (Homebrew)
brew tap FelixKratz/formulae
brew install sketchybar

# Start the service
brew services start sketchybar

# Reload after config changes
sketchybar --reload
```

## 📝 Customization

### Starship Prompt

Edit `~/Projects/dotfiles/starship/starship.toml` to customize your prompt:
- Change colors in the `style` fields
- Modify the format string
- Enable/disable git information
- Add language version indicators (nodejs, python, rust, etc.)

### Ghostty Themes

Create custom themes in `~/Projects/dotfiles/ghostty/themes/`:

```conf
# theme-mycustom.conf
background = #yourcolor
foreground = #yourcolor
palette = 0=#color1
# ... etc
```

Then update the theme list in `.zshrc` function `ghostty-theme()`.

## 🐛 Troubleshooting

### Prompt not changing
- Ensure starship is installed: `command -v starship`
- Check config path: `echo $STARSHIP_CONFIG`
- Reload shell: `source ~/.zshrc`

### CD not using zoxide
- Ensure zoxide is installed: `command -v zoxide`
- Check if initialized: `type cd` should show it's a function
- Reload shell: `source ~/.zshrc`

### Ghostty theme not changing
- Ensure config path is correct: `~/.config/ghostty/config`
- Check theme files exist in: `~/.config/ghostty/themes/`
- Restart Ghostty completely
- Check for syntax errors in config: `ghostty --validate-config`

## 📚 Additional Resources

- [Zoxide Documentation](https://github.com/ajeetdsouza/zoxide)
- [Starship Documentation](https://starship.rs/)
- [Ghostty Documentation](https://ghostty.org/)
