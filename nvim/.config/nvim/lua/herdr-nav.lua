-- Bridges Ctrl+h/j/k/l between Neovim splits, herdr panes, and tmux panes.
--
-- Inside a herdr pane: at a split edge, cross into the neighbouring herdr
-- pane (vim-herdr-navigation's herdr side).
-- Outside herdr (plain tmux, or no multiplexer): defer to the existing
-- nvim-tmux-navigation plugin so its tmux behaviour is unchanged.
--
-- Not the vendored vim-herdr-navigation/editor/nvim.lua: that file's tmux
-- fallback calls :TmuxNavigate* from vim-tmux-navigator, which isn't
-- installed here (nvim-tmux-navigation is used instead) — so its fallback
-- would silently no-op in tmux. This calls the real plugin instead.
-- ponytail: requiring nvim-tmux-navigation here assumes it's still the repo's
-- tmux nav plugin; if that's ever swapped out, update the require below.

local ok, tmux_nav = pcall(require, "nvim-tmux-navigation")

local function nav(wincmd, dir, tmux_fn)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    vim.fn.system({ vim.env.HERDR_BIN_PATH or "herdr", "pane", "focus", "--direction", dir, "--current" })
  elseif ok and tmux_fn then
    tmux_fn()
  end
end

local function map(lhs, wincmd, dir, tmux_fn, desc)
  vim.keymap.set("n", lhs, function()
    nav(wincmd, dir, tmux_fn)
  end, { silent = true, noremap = true, desc = desc })
end

map("<C-h>", "h", "left", ok and tmux_nav.NvimTmuxNavigateLeft, "Navigate left (herdr/tmux aware)")
map("<C-j>", "j", "down", ok and tmux_nav.NvimTmuxNavigateDown, "Navigate down (herdr/tmux aware)")
map("<C-k>", "k", "up", ok and tmux_nav.NvimTmuxNavigateUp, "Navigate up (herdr/tmux aware)")
map("<C-l>", "l", "right", ok and tmux_nav.NvimTmuxNavigateRight, "Navigate right (herdr/tmux aware)")
