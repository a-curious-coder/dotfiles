-- ┌─────────────────────────────────────────────────────────────┐
-- │ Neovim Core Settings                                        │
-- │ Purpose: Configure editor behavior and appearance           │
-- │ Note: Plugin-specific settings belong in plugin files       │
-- └─────────────────────────────────────────────────────────────┘

-- === LEADER KEYS ===
-- Set leader keys before any mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- === INDENTATION & TABS ===
vim.opt.expandtab = true       -- Use spaces instead of tabs
vim.opt.tabstop = 2            -- Tab width in spaces
vim.opt.softtabstop = 2        -- Soft tab width
vim.opt.shiftwidth = 2         -- Indent width for auto-indent

-- === LINE NUMBERS ===
vim.opt.number = true          -- Show line numbers
vim.opt.relativenumber = true  -- Show relative line numbers
vim.opt.signcolumn = "yes"     -- Always show sign column (prevents text shift)

-- === UI & APPEARANCE ===
vim.opt.cursorline = true      -- Highlight current line
vim.opt.showtabline = 2        -- Always show tab line
vim.opt.laststatus = 3         -- Global statusline (for better plugin support)
vim.g.background = "light"     -- Set background mode

-- Cursor styling and colors
vim.cmd([[highlight Cursor guifg=yellow guibg=yellow]])
vim.cmd([[highlight CursorLineNr guifg=yellow]])
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- === PERFORMANCE ===
vim.opt.updatetime = 250       -- Faster CursorHold events and LSP feedback
vim.opt.redrawtime = 1500      -- Allow more time for syntax highlighting on large files
-- Note: timeoutlen is set by which-key plugin

-- === FILE HANDLING ===
vim.opt.swapfile = false       -- Disable swap files (manual saves or :update)

-- === SEARCH & HIGHLIGHT ===
-- Clear search highlight with leader+h
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Highlight on yank for visual feedback
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
	desc = "Highlight yanked text briefly"
})

-- === WINDOW NAVIGATION ===
-- Note: Window navigation (<C-h/j/k/l>) is handled by nvim-tmux-navigation plugin
-- This allows seamless navigation between nvim splits and tmux panes
