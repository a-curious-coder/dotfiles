local function read_file(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

local function assert_contains(path, needle)
  local content = read_file(path)
  assert(content:find(needle, 1, true), string.format("Expected %s to contain %q", path, needle))
end

assert_contains("lua/vim-options.lua", "vim.fn.stdpath(\"state\")")
assert_contains("lua/vim-options.lua", "vim.fn.mkdir(undo_dir, \"p\")")
assert_contains("lua/vim-options.lua", "vim.fn.mkdir(backup_dir, \"p\")")
assert_contains("lua/vim-options.lua", "vim.opt.undodir = undo_dir .. \"//\"")
assert_contains("lua/vim-options.lua", "vim.opt.undofile = true")
assert_contains("lua/vim-options.lua", "vim.opt.backup = true")
assert_contains("lua/vim-options.lua", "vim.opt.writebackup = true")
assert_contains("lua/vim-options.lua", "vim.opt.backupdir = backup_dir .. \"//\"")

print("file persistence: ok")
