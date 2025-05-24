# Neovim Configuration

A modern Neovim configuration focused on Ruby on Rails, Python, and general development with strong LSP support.

## Features

- 🚀 Full LSP support with automatic server installation via Mason
- 🔍 Fuzzy finding with Telescope and fzf
- 📁 Multiple file explorers (Neo-tree and oil.nvim)
- 📑 Smart buffer management with Barbar
- 🏃 Fast file jumping with Harpoon
- 📦 Git integration with LazyGit
- 🎨 Beautiful UI with Catppuccin theme
- 💫 Auto-save functionality
- 🔖 Workspace/project management
- ⚡ Fast startup with lazy loading
- 📝 Advanced completion with nvim-cmp and LuaSnip
- 🌳 Enhanced syntax highlighting with Treesitter
- 📂 File folding with nvim-ufo
- 🖥️ Seamless tmux integration

## Prerequisites

- Neovim >= 0.10.0
- Git
- Node.js (for LSP servers)
- Ripgrep (for Telescope grep)
- A Nerd Font (for icons)
- tmux (optional, for nvim-tmux-navigation)
- Node.js package manager (npm or yarn)
- Ruby >= 2.7.0 (for Ruby/Rails development)
- Python >= 3.8 (for Python development)
- fzf (for enhanced fuzzy finding)

## Ruby/Rails Setup

The following tools are automatically installed via Mason:
- Solargraph (Ruby LSP)
- Ruby LSP
- ERB Lint
- Rubocop
- Rails Best Practices
- Reek

## Installation

1. Backup your existing Neovim configuration by moving ~/.config/nvim to ~/.config/nvim.bak

2. Clone this repository into ~/.config/nvim

3. Start Neovim and the configuration will automatically:
   - Install the plugin manager (lazy.nvim)
   - Install all configured plugins
   - Set up LSP servers via Mason

## Key Mappings

### General
- Space - Leader key
- Ctrl+n - Toggle file explorer
- Ctrl+p - Find files (git)
- Leader+pf - Find files (all)
- Leader+ps - Live grep with ripgrep
- Leader+pw - Search word under cursor
- Leader+pW - Search WORD under cursor
- Leader+Leader - Show recent files
- Leader+vh - Help tags
- Leader+pc - List commands
- Leader+pk - List keymaps
- Leader+pr - Resume last search

### Buffer Management (Barbar)
- Leader+bp - Previous buffer
- Leader+bn - Next buffer
- Leader+bc - Close buffer
- Leader+bb - Pick buffer by letter
- Alt+h/l - Move buffer left/right
- Leader+[1-9] - Go to buffer by number

### File Navigation
- Leader+a - Mark file in Harpoon
- Ctrl+e - Toggle Harpoon quick menu
- Ctrl+t/s/b/g - Navigate to Harpoon file 1/2/3/4
- "-" - Toggle oil.nvim file explorer

### Workspace Management
- Leader+wa - Add workspace
- Leader+wr - Remove workspace
- Leader+wl - List workspaces
- Leader+fp - Find projects

### Ruby/Rails Specific
- gd - Go to definition
- K - Show documentation
- Leader+ca - Code actions
- Leader+f - Format code
- Leader+t - Run nearest test
- Leader+T - Run test file

### Git Integration
- Leader+gg - Open LazyGit
- Leader+gf - Show file history
- Leader+gl - Show repository log
- Leader+gb - Show line blame

### LSP Features
- K - Hover documentation
- Leader+gd - Go to definition
- Leader+gr - Find references
- Leader+rn - Rename symbol
- Leader+ca - Code actions
- Leader+f - Format buffer
- Leader+d - Show diagnostics
- [d/]d - Previous/next diagnostic
- Leader+ls - Show LSP status
- Leader+ll - Show LSP log

## Verifying LSP Status

You can verify that LSP servers are running and attached to your files using these methods:

1. Check active LSP servers for current buffer:
   ```
   :LspInfo
   ```

2. View LSP logs:
   ```
   :LspLog
   ```

3. Check Mason-installed servers:
   ```
   :Mason
   ```

4. Quick LSP status check:
   - Type `K` on any symbol - if documentation appears, LSP is working
   - Type `gd` on a symbol - if it jumps to definition, LSP is working
   - Look for diagnostics (error/warning squiggles) - indicates active LSP

5. View attached LSP clients in lua:
   ```
   :lua print(vim.inspect(vim.lsp.get_active_clients()))
   ```

Common issues if LSP isn't working:
- Required language server not installed (use `:Mason` to install)
- Missing project-specific config files (e.g., `.rubocop.yml` for Ruby)
- LSP server executable not in PATH
- Syntax errors in configuration files

## Customisation

The configuration is modular and organized in the lua/plugins directory. Each plugin has its own configuration file that can be modified according to your preferences.

## Language Server Installation

Most language servers are automatically installed and managed through Mason. You can open the Mason UI with `:Mason` to install or manage language servers.

Common language servers that will be auto-installed:

### For Ruby/Rails
- ruby-lsp
- solargraph
- rubocop
- erb-lint

### For JavaScript/TypeScript
- typescript-language-server
- eslint-lsp

### For Python
- pyright
- pylsp

### For Lua
- lua-language-server

To install additional language servers:
1. Open Mason with `:Mason`
2. Navigate to the desired server
3. Press `i` to install

Mason will handle keeping these servers up to date and managing their dependencies.
