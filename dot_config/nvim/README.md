# Neovim Configuration

A modern Neovim configuration focused on Ruby on Rails, Python, and general development with strong LSP support.

## Features

- 🚀 Full LSP support for multiple languages
- 🛠 Integrated debugging capabilities
- 📦 Git integration with Fugitive and Gitsigns
- 🎨 Beautiful UI with Catppuccin theme
- 🌲 File explorer with Neo-tree
- 🔍 Fuzzy finding with Telescope
- ⚡ Fast startup with lazy loading
- 🧪 Testing support with vim-test
- 💎 Ruby on Rails specific tools and linters

## Prerequisites

- Neovim >= 0.9.0
- Git
- Node.js (for certain LSP servers)
- Ruby >= 2.7.0
- Python >= 3.8
- ripgrep (for Telescope grep)

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
- Leader+ps - Live grep
- Highlight word; `viw`

### Ruby/Rails Specific
- gd - Go to definition
- K - Show documentation
- Leader+ca - Code actions
- Leader+gf - Format code
- Leader+t - Run nearest test
- Leader+T - Run test file
- Leader+a - Run all tests

### Git
- Leader+gs - Git status
- Leader+gp - Preview hunk
- Leader+gt - Toggle line blame

### LSP
- K - Hover documentation
- Leader+gd - Go to definition
- Leader+gr - Find references
- Leader+ca - Code actions

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

## Required Ruby Gems

To ensure full functionality, install these gems globally:
- ruby-lsp
- rubocop
- reek
- lua-language-server

## Troubleshooting

If you encounter issues:

1. Update Neovim to the latest version
2. Run :checkhealth in Neovim
3. Ensure all prerequisites are installed
4. Try removing the plugin cache from ~/.local/share/nvim
