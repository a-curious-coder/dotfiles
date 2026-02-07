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

assert_contains("lua/vim-options.lua", "vim.opt.showmode = false")
assert_contains("lua/vim-options.lua", "vim.opt.cmdheight = 0")
assert_contains("lua/vim-options.lua", "vim.opt.shortmess:append({ I = true, W = true, c = true })")

print("calm ui: ok")
