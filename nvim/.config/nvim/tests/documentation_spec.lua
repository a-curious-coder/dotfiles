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

local readme = "README.md"

assert_contains(readme, "Daily Workflow")
assert_contains(readme, "<leader>fr")
assert_contains(readme, "<leader>fh")
assert_contains(readme, "<leader>ue")
assert_contains(readme, "<leader>cr")
assert_contains(readme, "<leader>?")

assert_not_contains(readme, "<Space><Space>")
assert_not_contains(readme, "<leader>rn")
assert_not_contains(readme, "<leader>e")
assert_not_contains(readme, "<leader>h")

print("documentation: ok")
