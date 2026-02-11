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

assert_contains("lua/vim-options.lua", "markdown-wikilinks")
assert_contains("lua/vim-options.lua", "follow_wikilink_under_cursor")
assert_contains("lua/vim-options.lua", "vim.keymap.set(\"n\", \"gf\", follow_wikilink_under_cursor")
assert_contains("README.md", "gf` (markdown)")
assert_contains("README.md", "[[wikilinks]]")

print("markdown navigation: ok")
