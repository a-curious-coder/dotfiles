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

-- Search keymaps stay under <leader>f
assert_contains("lua/vim-options.lua", "<leader>fh")
assert_not_contains("lua/vim-options.lua", "<leader>h")

-- Code keymaps stay under <leader>c
assert_contains("lua/lsp/keymaps.lua", "<leader>cr")
assert_not_contains("lua/lsp/keymaps.lua", "<leader>rn")

-- Find keymaps stay under <leader>f
assert_contains("lua/plugins/telescope.lua", "<leader>fr")
assert_not_contains("lua/plugins/telescope.lua", "<leader><leader>")

-- UI keymaps stay under <leader>u
assert_contains("lua/plugins/neo-tree.lua", "<leader>ue")
assert_not_contains("lua/plugins/neo-tree.lua", "<leader>e")

print("keymap surface: ok")
