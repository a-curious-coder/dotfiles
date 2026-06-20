local function systemlist_ok(cmd)
  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  return result
end

-- Search
vim.keymap.set("n", "<leader>fh", ":nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Buffer
vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { desc = "Close buffer" })

-- Copy relative file path (git-root-relative, falling back to cwd)
local function copy_to_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg("*", text)
  if vim.fn.has("clipboard") == 1 then return true end
  for _, cmd in ipairs({
    { "wl-copy" },
    { "xclip", "-selection", "clipboard" },
    { "xsel", "--clipboard", "--input" },
    { "pbcopy" },
  }) do
    if vim.fn.executable(cmd[1]) == 1 then
      vim.fn.system(cmd, text)
      if vim.v.shell_error == 0 then return true end
    end
  end
  return false
end

local function copy_current_file_relative_path()
  local absolute = vim.fn.expand("%:p")
  if absolute == "" then
    vim.notify("No file to copy path from", vim.log.levels.WARN)
    return
  end
  local base = vim.fn.getcwd()
  local git_root = systemlist_ok({ "git", "-C", vim.fn.fnamemodify(absolute, ":h"), "rev-parse", "--show-toplevel" })
  if git_root and git_root[1] and git_root[1] ~= "" then
    base = git_root[1]
  end
  local relative = vim.fs.relpath(vim.fs.normalize(base), vim.fs.normalize(absolute))
    or vim.fn.fnamemodify(absolute, ":.")
  if copy_to_clipboard(relative) then
    vim.notify("Copied: " .. relative, vim.log.levels.INFO)
  else
    vim.notify("Failed to copy to clipboard", vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command("CopyRelativePath", copy_current_file_relative_path, {
  desc = "Copy current file path relative to git root",
})
vim.keymap.set("n", "<leader>y", copy_current_file_relative_path, { desc = "Copy relative file path" })

-- Diagnostics
vim.g.diagnostics_enabled = true

local function resolve_git_base()
  for _, ref in ipairs({ "origin/main", "main", "origin/master", "master" }) do
    if systemlist_ok({ "git", "rev-parse", "--verify", ref }) then return ref end
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
      vim.fn.bufload(vim.fn.bufadd(file))
      loaded = loaded + 1
    end
  end
  local attempts = 0
  local function open_qf_when_ready()
    attempts = attempts + 1
    vim.diagnostic.setqflist()
    if #vim.fn.getqflist() > 0 then
      vim.cmd("copen")
      vim.notify("BranchDiagnostics: loaded " .. loaded .. " files", vim.log.levels.INFO)
      return
    end
    if attempts < 3 then vim.defer_fn(open_qf_when_ready, 700) else
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
