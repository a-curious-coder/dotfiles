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

assert_contains("lua/plugins/gitsigns.lua", "current_line_blame = true")
assert_contains("lua/plugins/gitsigns.lua", "gitsigns.blame_line({ full = true })")
assert_contains("lua/plugins/gitsigns.lua", "gitsigns.toggle_current_line_blame()")
assert_contains("lua/plugins/gitsigns.lua", "\"<leader>gb\"")
assert_contains("lua/plugins/gitsigns.lua", "\"<leader>gB\"")

print("git context: ok")
