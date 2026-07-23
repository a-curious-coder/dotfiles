-- Shared helpers used by file-templates.lua and test-files.lua.
local M = {}

function M.ensure_dir(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

function M.open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.project_root(start_dir)
  if vim.fs and vim.fs.find then
    local found = vim.fs.find(".git", { path = start_dir, upward = true })
    if found and found[1] then
      return vim.fn.fnamemodify(found[1], ":h")
    end
  end
  return vim.fn.getcwd()
end

return M
