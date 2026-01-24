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
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Tab width in spaces
vim.opt.softtabstop = 2 -- Soft tab width
vim.opt.shiftwidth = 2 -- Indent width for auto-indent

-- === LINE NUMBERS ===
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Disable relative line numbers
vim.opt.signcolumn = "yes" -- Always show sign column (prevents text shift)

-- === UI & APPEARANCE ===
vim.opt.cursorline = true -- Highlight current line
vim.opt.showtabline = 0 -- Hide tabline until multiple buffers are open
vim.opt.laststatus = 3 -- Global statusline (for better plugin support)
vim.opt.background = "dark" -- Set background mode
vim.opt.showmode = false -- Hide mode text (statusline already shows it)
vim.opt.cmdheight = 0 -- Hide the command line unless needed
vim.opt.shortmess:append({ I = true, W = true, c = true }) -- Reduce message noise (intro/write/completion)

local function update_tabline_visibility()
	local listed_buffers = #vim.fn.getbufinfo({ buflisted = 1 })
	vim.opt.showtabline = listed_buffers > 1 and 2 or 0
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("tabline-visibility", { clear = true }),
	callback = update_tabline_visibility,
	desc = "Show tabline only when multiple buffers are listed",
})

update_tabline_visibility()

-- === CLIPBOARD ===
vim.opt.clipboard = "unnamedplus"

-- Cursor styling and colors
vim.cmd([[highlight Cursor guifg=yellow guibg=yellow]])
vim.cmd([[highlight CursorLineNr guifg=yellow]])
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- === PERFORMANCE ===
vim.opt.updatetime = 250 -- Faster CursorHold events and LSP feedback
vim.opt.redrawtime = 1500 -- Allow more time for syntax highlighting on large files
-- Note: timeoutlen is set by which-key plugin

-- === FILE HANDLING ===
local state_dir = vim.fn.stdpath("state")
local undo_dir = state_dir .. "/undo"
local backup_dir = state_dir .. "/backup"
vim.fn.mkdir(undo_dir, "p")
vim.fn.mkdir(backup_dir, "p")
vim.opt.undodir = undo_dir .. "//" -- Keep undo files in a stable state dir
vim.opt.undofile = true -- Persistent undo history
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.backupdir = backup_dir .. "//"
vim.opt.swapfile = false -- Disable swap files (manual saves or :update)

-- === SEARCH & HIGHLIGHT ===
vim.opt.ignorecase = true -- Case-insensitive search by default
vim.opt.smartcase = true -- Use case-sensitive search if uppercase appears
vim.opt.incsearch = true -- Show matches as you type
-- Clear search highlight with leader+f+h
vim.keymap.set("n", "<leader>fh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Highlight on yank for visual feedback
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
	desc = "Highlight yanked text briefly",
})

-- === UI TOGGLES ===
vim.g.diagnostics_enabled = true
vim.diagnostic.config({
	virtual_text = {
		spacing = 2,
		prefix = "●",
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	float = {
		border = "rounded",
		source = "if_many",
		scope = "cursor",
		focusable = false,
	},
})

local function systemlist_ok(cmd)
	local result = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return result
end

local function resolve_git_base()
	local candidates = { "origin/main", "main", "origin/master", "master" }
	for _, ref in ipairs(candidates) do
		if systemlist_ok({ "git", "rev-parse", "--verify", ref }) then
			return ref
		end
	end
	return nil
end

vim.api.nvim_create_user_command("BranchDiagnostics", function(opts)
	if vim.fn.executable("git") == 0 then
		vim.notify("BranchDiagnostics: git not found", vim.log.levels.ERROR)
		return
	end

	local base = opts.args ~= "" and opts.args or resolve_git_base()
	if not base then
		vim.notify("BranchDiagnostics: no base ref found (try :BranchDiagnostics main)", vim.log.levels.WARN)
		return
	end

	local merge_base = systemlist_ok({ "git", "merge-base", base, "HEAD" })
	local base_ref = merge_base and merge_base[1] or base
	local files = systemlist_ok({ "git", "diff", "--name-only", base_ref .. "..HEAD" })
	if not files or vim.tbl_isempty(files) then
		vim.notify("BranchDiagnostics: no changed files", vim.log.levels.INFO)
		return
	end

	local loaded = 0
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local buf = vim.fn.bufadd(file)
			vim.fn.bufload(buf)
			loaded = loaded + 1
		end
	end

	local attempts = 0
	local function open_qf_when_ready()
		attempts = attempts + 1
		vim.diagnostic.setqflist()
		local qf = vim.fn.getqflist()
		if #qf > 0 then
			vim.cmd("copen")
			vim.notify("BranchDiagnostics: loaded " .. loaded .. " files", vim.log.levels.INFO)
			return
		end

		if attempts < 3 then
			vim.defer_fn(open_qf_when_ready, 700)
		else
			vim.notify("BranchDiagnostics: no diagnostics found yet", vim.log.levels.INFO)
		end
	end

	vim.defer_fn(open_qf_when_ready, 700)
end, { nargs = "?", desc = "Diagnostics for files changed on the branch" })

vim.keymap.set("n", "<leader>cd", ":BranchDiagnostics<CR>", { desc = "Branch diagnostics" })

vim.keymap.set("n", "<leader>ud", function()
	vim.g.diagnostics_enabled = not vim.g.diagnostics_enabled
	if vim.g.diagnostics_enabled then
		vim.diagnostic.enable()
		vim.notify("Diagnostics enabled", vim.log.levels.INFO)
	else
		vim.diagnostic.disable()
		vim.notify("Diagnostics disabled", vim.log.levels.WARN)
	end
end, { desc = "Toggle diagnostics" })

local function copy_to_clipboard(text)
	vim.fn.setreg("+", text)
	vim.fn.setreg("*", text)

	if vim.fn.has("clipboard") == 1 then
		return true
	end

	if vim.fn.executable("pbcopy") == 1 then
		vim.fn.system("pbcopy", text)
		return vim.v.shell_error == 0
	end

	if vim.fn.executable("wl-copy") == 1 then
		vim.fn.system({ "wl-copy" }, text)
		return vim.v.shell_error == 0
	end

	if vim.fn.executable("xclip") == 1 then
		vim.fn.system({ "xclip", "-selection", "clipboard" }, text)
		return vim.v.shell_error == 0
	end

	if vim.fn.executable("xsel") == 1 then
		vim.fn.system({ "xsel", "--clipboard", "--input" }, text)
		return vim.v.shell_error == 0
	end

	return false
end

vim.keymap.set("n", "<leader>y", function()
	local path = vim.fn.expand("%")
	if path == "" then
		vim.notify("No file to copy path from", vim.log.levels.WARN)
		return
	end

	if copy_to_clipboard(path) then
		vim.notify("Copied relative path: " .. path, vim.log.levels.INFO)
	else
		vim.notify("Failed to copy to clipboard", vim.log.levels.ERROR)
	end
end, { desc = "Copy relative file path" })

-- === WINDOW NAVIGATION ===
-- Note: Window navigation (<C-h/j/k/l>) is handled by nvim-tmux-navigation plugin
-- This allows seamless navigation between nvim splits and tmux panes
