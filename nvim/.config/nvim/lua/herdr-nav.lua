-- Ctrl+h/j/k/l moves between Neovim splits, and at a split edge crosses into
-- the neighbouring herdr pane (vim-herdr-navigation's herdr side). Outside
-- herdr it is plain window navigation. tmux support was removed with tmux.

local function nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    vim.fn.system({ vim.env.HERDR_BIN_PATH or "herdr", "pane", "focus", "--direction", dir, "--current" })
  end
end

for lhs, d in pairs({ ["<C-h>"] = { "h", "left" }, ["<C-j>"] = { "j", "down" }, ["<C-k>"] = { "k", "up" }, ["<C-l>"] = { "l", "right" } }) do
  vim.keymap.set("n", lhs, function()
    nav(d[1], d[2])
  end, { silent = true, noremap = true, desc = "Navigate " .. d[2] .. " (herdr aware)" })
end
