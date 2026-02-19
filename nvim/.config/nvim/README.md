# Neovim Configuration

A modern, modular Neovim configuration focused on web development (TypeScript, Vue), Ruby on Rails, Python, and general development with strong LSP support.

This README is the source of truth for this Neovim setup.

## ✨ Features

- 🚀 **LSP + completion** with Mason, nvim-lspconfig, nvim-cmp, and LuaSnip
- 🔍 **Fuzzy finding** with Telescope (fzf native + recent-files)
- 📁 **Tree file explorer** with Neo-tree
- 🎨 **Flexoki** theme + **mini.icons** for lightweight devicons
- 📝 **Formatting** via Conform
- ✂️ **Snippets** with LuaSnip + nvim-scissors (local, editable library)
- 🖥️ **tmux-aware navigation** with nvim-tmux-navigation
- ❓ **Keybinding discovery** with which-key (press Space and wait)
- 📚 **Markdown read view** with render-markdown (toggle inline or preview split)
- 💾 **Autosave on edit** with save-on-change + save-on-leave/focus-loss

## 📋 Prerequisites

**Required:**
- Neovim >= 0.11.0
- Git
- Node.js (for LSP servers)
- ripgrep (for Telescope live grep)
- A Nerd Font (for icons)

**Optional:**
- fd (faster file finding)
- make + C compiler (for telescope-fzf-native)
- tmux (for nvim-tmux-navigation)
- Ruby >= 2.7.0 (for Ruby/Rails development)
- Python >= 3.8 (for Python development)

## 🚀 Installation

> **⚠️ IMPORTANT:** Backup your existing configuration first!

```bash
# 1. Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d)
mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%Y%m%d)

# 2. From your dotfiles directory, stow the nvim config
cd ~/.dotfiles
stow nvim

# 3. Install dependencies (recommended)
./install-modern-tools.sh

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

For implementation details, read the files in `lua/` and `lua/plugins/`.

## 🎯 Key Mappings

> **Tip:** Press `<Space>` (leader) to see available keybindings via which-key, or `<leader>?` to search keybindings.

### File & Search (`<leader>f`)
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (git-aware, falls back to all files) |
| `<leader>fb` | Find buffers |
| `<leader>fs` | Live grep (includes hidden files) |
| `<leader>fo` | Live grep in open files |
| `<leader>fr` | Recent files |
| `<leader>fh` | Clear search highlight |

### Buffers
| Key | Action |
|-----|--------|
| `[b` / `]b` | Previous / next buffer |
| `<leader>1`…`<leader>9` | Jump to buffer by position |

### Git
| Key | Action |
|-----|--------|
| `<leader>gg` | LazyGit |
| `<leader>gf` | LazyGit current file |
| `<leader>gb` | Git blame line |
| `<leader>gB` | Toggle line blame |

### Code & LSP
| Key | Action |
|-----|--------|
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gr` | Show references |
| `<leader>ca` | Code actions |
| `<leader>cd` | Branch diagnostics |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | Format buffer (via Conform) |
| `[d` / `]d` | Previous / next diagnostic |
| `gl` | Show diagnostic float |

### UI Toggles (`<leader>u`)
| Key | Action |
|-----|--------|
| `<leader>e` | Toggle Neo-tree |
| `<leader>ue` | Toggle Neo-tree |
| `<leader>ud` | Toggle diagnostics |
| `<leader>um` | Toggle markdown read view |
| `<leader>uM` | Open markdown preview split |

### Utility
| Key | Action |
|-----|--------|
| `<leader>y` | Copy relative file path |
| `<leader>?` | Search keymaps |
| `<leader>ct` | Create/open Vue test (prefers co-located, searches repo if missing) |
| `gf` (markdown) | Follow file links and Obsidian-style `[[wikilinks]]` |
| `<leader>tt` | Toggle floating terminal |

### Snippets (`<leader>s`)
| Key | Action |
|-----|--------|
| `<leader>sa` | Add snippet (normal/visual) |
| `<leader>se` | Edit snippet |
| `<leader>ss` | Insert snippet (searchable picker) |
| `<leader>sE` | Edit any snippet (all filetypes) |

### UX Defaults
- Persistent undo enabled
- System clipboard is opt-in via `"+` register (for example `"+y`)
- Intro screen and mode text hidden
- Inline diagnostics enabled (details on demand with `gl`)
- Inline git blame enabled (toggle with `<leader>gB`)
- Buffer tabs hidden when only one file is open
- Modified files autosave after edits and when changing focus/buffers

## Handbook

File over app.

Notes live as plain markdown files in your filesystem.

Links are the interface.

Use `[[wikilinks]]` while drafting and follow them with `gf`. If note names collide, use explicit paths in the link.

Prefer durable files.

Keep links and filenames readable, and use markdown links when you need maximum interoperability outside Obsidian.

## 🧭 Daily Workflow
- Jump to a file with `<leader>ff` or reopen with `<leader>fr`.
- Search across the repo with `<leader>fs` or only open files with `<leader>fo`, then clear highlights with `<leader>fh`.
- Toggle the tree with `<leader>e`, hop buffers with `<leader>fb` and `[b` / `]b`.
- Use `<leader>um` in markdown files for a readable render, or `<leader>uM` for side-by-side preview.
- Use `gf` in markdown files to open `[[wikilinks]]` (including `[[note#heading]]`).
- Use `<leader>tt` for quick shell commands without leaving Neovim.
- Rely on autosave while writing; files are persisted on edit and when leaving buffers/focus.
- Navigate code with `gd`/`gr`, inspect docs with `K`, use `<leader>ca`/`<leader>cr` for edits.
- Review diagnostics with `[d`/`]d` and `gl`, or use `<leader>cd` for branch-only checks.
- Open git context with `<leader>gg`, one-shot blame with `<leader>gb`, toggle inline blame with `<leader>gB`.

## 🎨 Customization

### Changing Theme

Edit `lua/plugins/flexoki.lua` and/or `lua/vim-options.lua`:

```lua
vim.opt.background = "dark" -- or "light"
vim.cmd.colorscheme("flexoki-dark") -- or "flexoki-light"
```

### Adding a New LSP Server

1. Add to `lua/lsp/servers.lua`:
   ```lua
   new_server = {},  -- Use defaults, or add custom settings
   ```

2. Restart Neovim - Mason will auto-install it

### Snippets

- Global snippets live in `nvim/.config/nvim/snippets` (VS Code snippet format).
- Vue, Rails/RSpec, and Pytest starter snippets are included and editable.
- Use `<leader>ss` to search snippets and insert directly at the cursor.
- Use `<leader>sE` to search and edit snippets across all filetypes.
- Use `<leader>sa` to add new snippets and `<leader>se` to edit existing ones.

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
:BranchDiagnostics  " Diagnostics for files changed on the branch
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
- `vue-language-server` (Vue Language Server, `vue_ls`)
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
- Review `init.lua` for startup wiring
- Review `lua/vim-options.lua` for core editor behavior
- Review individual plugin files in `lua/plugins/` for plugin-specific configuration

---

**Version:** 1.0  
**Last Updated:** January 23, 2026  
**Maintained by:** Callum McLennan
