vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.opt.expandtab = true

vim.opt.showtabline = 2
vim.wo.relativenumber = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.background = "light"

vim.opt.swapfile = false
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.wo.number = true

-- Improve performance
vim.opt.updatetime = 100 -- Faster completion
vim.opt.timeoutlen = 300 -- Faster key sequence completion
vim.opt.redrawtime = 1500 -- Allow more time for loading syntax on large files
-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
