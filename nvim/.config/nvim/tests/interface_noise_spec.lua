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

local function assert_not_contains(path, needle)
  local content = read_file(path)
  assert(not content:find(needle, 1, true), string.format("Expected %s to not contain %q", path, needle))
end

assert_contains("lua/vim-options.lua", "vim.opt.showtabline = 0")
assert_contains("lua/vim-options.lua", "vim.opt.showtabline = listed_buffers > 1 and 2 or 0")
assert_not_contains("lua/vim-options.lua", "vim.opt.showtabline = 2")

assert_contains("lua/plugins/neo-tree.lua", "visible = false")
assert_contains("lua/plugins/neo-tree.lua", "show_hidden_count = false")
assert_contains("lua/plugins/neo-tree.lua", "hide_dotfiles = true")
assert_contains("lua/plugins/neo-tree.lua", "hide_gitignored = true")
assert_contains("lua/plugins/neo-tree.lua", "[\"H\"] = \"toggle_hidden\"")

print("interface noise: ok")
