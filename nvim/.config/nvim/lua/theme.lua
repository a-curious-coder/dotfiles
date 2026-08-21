local M = {}

function M.get()
  local f = io.open(vim.fn.stdpath("config") .. "/theme", "r")
  local theme = f and f:read("*l") or "flexoki-dark"
  if f then f:close() end
  return theme
end

return M
