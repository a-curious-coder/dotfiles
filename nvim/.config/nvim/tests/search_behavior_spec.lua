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

assert_contains("lua/vim-options.lua", "vim.opt.ignorecase = true")
assert_contains("lua/vim-options.lua", "vim.opt.smartcase = true")
assert_contains("lua/vim-options.lua", "vim.opt.incsearch = true")

assert_contains("lua/plugins/telescope.lua", "pcall(builtin.git_files")
assert_contains("lua/plugins/telescope.lua", "builtin.find_files(vim.tbl_extend(\"force\", opts, {")
assert_contains("lua/plugins/telescope.lua", "hidden = true")

print("search behavior: ok")
