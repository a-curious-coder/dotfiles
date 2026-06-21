vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ponytail: nvim-treesitter query_predicates crash on Nvim 0.12.3 — nil node
-- passed to get_node_text. Guard here until upstream fixes the incompatibility.
local _get_node_text = vim.treesitter.get_node_text
vim.treesitter.get_node_text = function(node, source, opts)
  if node == nil then return "" end
  return _get_node_text(node, source, opts)
end

-- Ensure Mason binaries are on PATH for LSP servers
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 and not (vim.env.PATH or ""):find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
end

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "yes"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldcolumn = "1"

vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.background = "dark"
vim.opt.showmode = false
vim.opt.cmdheight = 0
vim.opt.shortmess:append({ I = true, W = true, c = true })

vim.opt.clipboard = ""

vim.cmd([[highlight Cursor guifg=yellow guibg=yellow]])
vim.cmd([[highlight CursorLineNr guifg=yellow]])
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

vim.opt.updatetime = 250
vim.opt.redrawtime = 1500

local state_dir = vim.fn.stdpath("state")
local undo_dir = state_dir .. "/undo"
local backup_dir = state_dir .. "/backup"
vim.fn.mkdir(undo_dir, "p")
vim.fn.mkdir(backup_dir, "p")
vim.opt.undodir = undo_dir .. "//"
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.backupdir = backup_dir .. "//"
vim.opt.swapfile = false

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
  max_width = math.floor(vim.o.columns * 0.7),
  max_height = math.floor(vim.o.lines * 0.8),
})

vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
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
