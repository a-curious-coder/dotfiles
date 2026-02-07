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

assert_contains("lua/vim-options.lua", "virtual_text = {")
assert_contains("lua/vim-options.lua", "prefix = \"●\"")
assert_contains("lua/vim-options.lua", "scope = \"cursor\"")
assert_contains("lua/vim-options.lua", "focusable = false")

print("diagnostic views: ok")
