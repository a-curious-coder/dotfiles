local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("vim-options")
require("lazy").setup("plugins")
-- Set cursor color to yellow
vim.cmd([[highlight Cursor guifg=yellow guibg=yellow]])

-- Set current line number color to yellow
vim.cmd([[highlight CursorLineNr guifg=yellow]])

-- Enable line number display
vim.opt.number = true

-- Enable cursor line highlighting
vim.opt.cursorline = true

-- Set cursor style (optional)
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
