-- ┌─────────────────────────────────────────────────────────────┐
-- │ Neovim Core Settings                                        │
-- │ Purpose: Configure editor behavior and appearance           │
-- │ Note: Plugin-specific settings belong in plugin files       │
-- └─────────────────────────────────────────────────────────────┘

-- === LEADER KEYS ===
-- Set leader keys before any mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Ensure Mason binaries are available for LSP servers
do
	local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
	if vim.fn.isdirectory(mason_bin) == 1 then
		local sep = vim.fn.has("win32") == 1 and ";" or ":"
		local path = vim.env.PATH or ""
		if not string.find(path, mason_bin, 1, true) then
			vim.env.PATH = mason_bin .. sep .. path
		end
	end
end

-- === INDENTATION & TABS ===
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Tab width in spaces
vim.opt.softtabstop = 2 -- Soft tab width
vim.opt.shiftwidth = 2 -- Indent width for auto-indent

-- === LINE NUMBERS ===
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Disable relative line numbers
vim.opt.signcolumn = "yes" -- Always show sign column (prevents text shift)

-- === FOLDING ===
vim.opt.foldmethod = "expr" -- Use Tree-sitter for folds
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99 -- Keep folds open by default
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldcolumn = "1"

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

local function autosave_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	if vim.bo[bufnr].buftype ~= "" then
		return
	end

	if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
		return
	end

	if vim.api.nvim_buf_get_name(bufnr) == "" then
		return
	end

	if not vim.bo[bufnr].modified then
		return
	end

	vim.api.nvim_buf_call(bufnr, function()
		vim.cmd("silent! update")
	end)
end

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHoldI", "FocusLost", "BufLeave" }, {
	group = vim.api.nvim_create_augroup("autosave-on-edit", { clear = true }),
	callback = function(args)
		autosave_buffer(args.buf)
	end,
	desc = "Auto-save modified files during editing and on focus changes",
})

-- === SEARCH & HIGHLIGHT ===
vim.opt.ignorecase = true -- Case-insensitive search by default
vim.opt.smartcase = true -- Use case-sensitive search if uppercase appears
vim.opt.incsearch = true -- Show matches as you type
-- Clear search highlight
vim.keymap.set("n", "<leader>fh", ":nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

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

vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { desc = "Close buffer" })

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

-- === MARKDOWN LINK NAVIGATION ===
local function find_wikilink_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local start = 1

	while true do
		local open_start, open_end = line:find("%[%[", start)
		if not open_start then
			return nil
		end

		local close_start, close_end = line:find("%]%]", open_end + 1)
		if not close_start then
			return nil
		end

		if col >= open_start and col <= close_end then
			return line:sub(open_end + 1, close_start - 1)
		end

		start = close_end + 1
	end
end

local function split_wikilink_target(raw_target)
	local target = raw_target:gsub("^%s+", ""):gsub("%s+$", "")
	target = target:match("^[^|]+") or target

	local file_part, anchor = target:match("^(.-)#(.+)$")
	if file_part == nil then
		file_part = target
	end
	if file_part == "" then
		file_part = nil
	end

	return file_part, anchor
end

local function is_absolute_path(path)
	return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
end

local function resolve_wikilink_path(file_part)
	if not file_part then
		return vim.api.nvim_buf_get_name(0)
	end

	local target = file_part
	if not target:match("%.[^/\\]+$") then
		target = target .. ".md"
	end

	local full_path
	if target:sub(1, 1) == "/" then
		full_path = vim.fn.fnamemodify(vim.fn.getcwd() .. target, ":p")
	elseif is_absolute_path(target) then
		full_path = target
	else
		local current_dir = vim.fn.expand("%:p:h")
		full_path = vim.fn.fnamemodify(current_dir .. "/" .. target, ":p")
	end

	if vim.fn.filereadable(full_path) == 1 then
		return full_path
	end

	return nil
end

local function jump_to_anchor(anchor)
	if not anchor or anchor == "" then
		return
	end

	local trimmed_anchor = anchor:gsub("^%s+", ""):gsub("%s+$", "")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	if trimmed_anchor:sub(1, 1) == "^" then
		for line_nr, line in ipairs(lines) do
			if line:find(trimmed_anchor, 1, true) then
				vim.api.nvim_win_set_cursor(0, { line_nr, 0 })
				return
			end
		end
	end

	for line_nr, line in ipairs(lines) do
		local heading_text = line:match("^#+%s*(.-)%s*$")
		if heading_text and heading_text == trimmed_anchor then
			vim.api.nvim_win_set_cursor(0, { line_nr, 0 })
			return
		end
	end
end

local function follow_wikilink_under_cursor()
	local raw_target = find_wikilink_under_cursor()
	if not raw_target then
		vim.cmd.normal({ args = { "gf" }, bang = true })
		return
	end

	local file_part, anchor = split_wikilink_target(raw_target)
	local target_path = resolve_wikilink_path(file_part)
	if not target_path then
		vim.notify("Wikilink target not found: " .. (file_part or raw_target), vim.log.levels.WARN)
		return
	end

	vim.cmd.edit(vim.fn.fnameescape(target_path))
	jump_to_anchor(anchor)
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("markdown-wikilinks", { clear = true }),
	pattern = "markdown",
	callback = function(ev)
		vim.keymap.set("n", "gf", follow_wikilink_under_cursor, {
			buffer = ev.buf,
			desc = "Follow file or wikilink",
		})
	end,
	desc = "Use gf to follow Obsidian-style wikilinks in markdown",
})

-- === WINDOW NAVIGATION ===
-- Note: Window navigation (<C-h/j/k/l>) is handled by nvim-tmux-navigation plugin
-- This allows seamless navigation between nvim splits and tmux panes
