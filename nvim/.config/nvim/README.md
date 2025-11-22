# Neovim Configuration

A modern, modular Neovim configuration focused on web development (TypeScript, Vue), Ruby on Rails, Python, and general development with strong LSP support.

> **📖 See [DESIGN_PLAN.md](DESIGN_PLAN.md) for architecture details and design rationale**

## ✨ Features

- 🚀 **Full LSP support** with automatic server installation via Mason
- 🔍 **Fuzzy finding** with Telescope and fzf
- 📁 **File explorer** with Neo-tree
- 📑 **Smart buffer management** with Barbar tabs
- 📦 **Git integration** with LazyGit
- 🎨 **Beautiful UI** with Catppuccin theme
- 💫 **Auto-save** on file switch
- ⚡ **Fast startup** with lazy loading
- 📝 **Advanced completion** with nvim-cmp and LuaSnip
- 🌳 **Enhanced syntax** highlighting with Treesitter
- 📂 **Code folding** with nvim-ufo
- 🖥️ **Seamless tmux integration** for split navigation
- ❓ **Keybinding discovery** with which-key (press Space and wait)

## 📋 Prerequisites

**Required:**
- Neovim >= 0.10.0
- Git
- Node.js (for LSP servers)
- ripgrep (for Telescope grep)
- fd (for file finding)
- fzf (for fuzzy finding)
- A Nerd Font (for icons)

**Optional:**
- tmux (for nvim-tmux-navigation)
- Ruby >= 2.7.0 (for Ruby/Rails development)
- Python >= 3.8 (for Python development)
- LazyGit (for git integration)

## 🚀 Installation

> **⚠️ IMPORTANT:** Backup your existing configuration first!

```bash
# 1. Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d)
mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%Y%m%d)

# 2. From your dotfiles directory, stow the nvim config
cd ~/.dotfiles
stow nvim

# 3. Install dependencies (if using the setup script)
./setup --categories cli,development

# 4. Launch Neovim - plugins install automatically
nvim
```

**First launch will take 2-5 minutes** to download and install all plugins and LSP servers. Subsequent launches are < 50ms.

### Verification

After installation, verify everything works:

```vim
:checkhealth        " Check for issues
:Lazy               " View installed plugins  
:Mason              " View installed LSP servers
:LspInfo            " Check LSP status in current buffer
```

## 🗂️ Configuration Structure

```
nvim/.config/nvim/
├── init.lua                 # Bootstrap lazy.nvim
├── lua/
│   ├── vim-options.lua      # Core editor settings
│   ├── lsp/                 # LSP configuration
│   │   ├── servers.lua      # Server definitions
│   │   └── keymaps.lua      # LSP keybindings
│   └── plugins/             # Plugin specifications
│       ├── lsp-config.lua   # LSP & Mason setup
│       ├── completions.lua  # Completion engine
│       ├── telescope.lua    # Fuzzy finder
│       └── ...              # Other plugins
└── lazy-lock.json           # Plugin version lock
```

See [DESIGN_PLAN.md](DESIGN_PLAN.md) for detailed architecture explanation.

## 🎯 Key Mappings

> **Tip:** Press `<Space>` (leader) to see all available keybindings via which-key

### General Navigation
| Key | Action |
|-----|--------|
| `<Space>` | Leader key (wait for which-key popup) |
| `<leader>?` | Show all keybindings |
| `<C-n>` | Toggle Neo-tree file explorer |
| `<C-h/j/k/l>` | Navigate splits (works with tmux panes) |

### File & Search (Leader + f)
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (all) |
| `<leader>fg` | Find files (git) |
| `<leader>fb` | Find buffers |
| `<leader>fs` | Live grep |
| `<leader>fw` | Search word under cursor |
| `<leader>fW` | Search WORD under cursor |
| `<leader>fr` | Resume last search |
| `<leader>fh` | Help tags |
| `<leader>fc` | Commands |
| `<leader>fk` | Keymaps |
| `<Space><Space>` | Recent files |

### Buffer Management (Leader + b)
| Key | Action |
|-----|--------|
| `<leader>bp` | Previous buffer |
| `<leader>bn` | Next buffer |
| `<leader>bf` | First buffer |
| `<leader>bl` | Last buffer |
| `<leader>bb` | Pick buffer (by letter) |
| `<leader>bc` | Close buffer |
| `<leader>bx` | Pick buffer to close |
| `<leader>[1-9]` | Go to buffer by number |
| `<Alt-h/l>` | Move buffer left/right |
| `<Alt-p>` | Pin/unpin buffer |

### LSP (Code Intelligence)
| Key | Action |
|-----|--------|
| `K` | Show hover documentation |
| `<leader>gd` | Go to definition |
| `<leader>gr` | Show references |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename symbol |
| `<leader>f` | Format code (via Conform) |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>d` | Show diagnostic |
| `<leader>ls` | LSP info |

### Git
| Key | Action |
|-----|--------|
| `<leader>gg` | Open LazyGit |

### Utility
| Key | Action |
|-----|--------|
| `<leader>h` | Clear search highlight |

## 🎨 Customization

### Changing Theme

Edit `lua/plugins/catppuccin.lua`:

```lua
opts = {
  flavour = "mocha",  -- latte, frappe, macchiato, or mocha
}
```

### Adding a New LSP Server

1. Add to `lua/lsp/servers.lua`:
   ```lua
   new_server = {},  -- Use defaults, or add custom settings
   ```

2. Restart Neovim - Mason will auto-install it

### Adding a New Plugin

1. Create `lua/plugins/plugin-name.lua`:
   ```lua
   return {
     "author/plugin-name",
     event = "VeryLazy",  -- Lazy load
     config = function()
       require("plugin-name").setup({})
     end,
   }
   ```


2. Restart Neovim - Lazy will auto-install it

## 🔧 Maintenance

### Updating Plugins

```vim
:Lazy update        " Update all plugins to latest
:Lazy clean         " Remove unused plugins
:Lazy restore       " Restore to locked versions (rollback after breaking update)
:Lazy profile       " Check startup performance
```

### Managing LSP Servers

```vim
:Mason              " Open Mason UI to manage LSP servers
:MasonUpdate        " Update Mason registry
:checkhealth mason  " Check Mason installation health
```

### Checking Configuration Health

```vim
:checkhealth        " Comprehensive health check
:LspInfo            " Check LSP status for current buffer
:LspLog             " View LSP error logs
```

## 🐛 Troubleshooting

### Plugins Not Installing

**Symptoms:** Plugins missing after first launch

**Solutions:**
- Check internet connection (downloads required)
- Run `:Lazy restore` to retry installation
- Check `:Lazy log` for error messages
- Manually trigger: `:Lazy sync`

### LSP Not Working

**Symptoms:** No autocomplete, diagnostics, or go-to-definition

**Solutions:**
1. Check server status: `:LspInfo`
2. Verify server installed: `:Mason`
3. Check language tools: `ruby --version`, `python --version`, `node --version`
4. Review logs: `:LspLog`
5. Run health check: `:checkhealth lsp`

**Common Issues:**
- Language runtime not installed
- Project missing config files (`.rubocop.yml`, `pyproject.toml`, etc.)
- Server executable not in PATH

### Slow Startup

**Symptoms:** Neovim takes > 200ms to start

**Solutions:**
1. Profile startup: `:Lazy profile`
2. Check for plugins with `lazy = false`
3. Ensure plugins use proper lazy loading (`event`, `cmd`, `keys`)
4. Remove unused plugins: `:Lazy clean`

### Keybinding Conflicts

**Symptoms:** Keybinding doesn't work as expected

**Solutions:**
1. List all keymaps: `:Telescope keymaps`
2. Check which-key: `<Space>` (wait for popup)
3. Search for conflicts: `:verbose map <keybinding>`

## 📚 Language-Specific Notes

### Ruby/Rails

**Auto-installed tools via Mason:**
- `ruby-lsp` - Ruby language server
- `rubocop` - Linter and formatter  
- `erb-lint` - ERB template linter

**Project setup:**
Create `.rubocop.yml` in project root for linting configuration.

### Python

**Auto-installed tools via Mason:**
- `pyright` - Type checking
- `pylsp` - Language server
- `black` - Formatter (via Conform)

**Project setup:**
Use `pyproject.toml` or `setup.cfg` for project configuration.

### TypeScript/JavaScript/Vue

**Auto-installed tools via Mason:**
- `ts_ls` (TypeScript Language Server)
- `volar` (Vue Language Server)
- `eslint` - Linter
- `prettier` - Formatter (via Conform)

**Project setup:**
Ensure `tsconfig.json` exists for TypeScript projects.

### Lua

**Auto-installed tools via Mason:**
- `lua_ls` (Lua Language Server)
- `stylua` - Formatter (via Conform)

Automatically configured for Neovim development.

## 📖 Learning Resources

### For Vim Beginners
- Run `:Tutor` for interactive Vim tutorial
- Press `<Space>` to explore keybindings with which-key
- Use `:Telescope keymaps` to search available shortcuts

### For This Configuration
- See [DESIGN_PLAN.md](DESIGN_PLAN.md) for architecture and design rationale
- Check [CHANGES_APPLIED.md](CHANGES_APPLIED.md) for recent improvements
- Review individual plugin files in `lua/plugins/` for specific configurations

---

**Version:** 1.0  
**Last Updated:** October 12, 2025  
**Maintained by:** Callum McLennan
