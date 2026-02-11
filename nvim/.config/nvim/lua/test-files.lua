local M = {}

local function current_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":p")
end

local function is_vue_file(path)
  return path:match("%.vue$") ~= nil or vim.bo.filetype == "vue"
end

local function test_candidates(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  local base = vim.fn.fnamemodify(path, ":t:r")
  return {
    dir .. "/" .. base .. ".spec.ts",
  }
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function ensure_dir(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function component_name(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

local function write_vue_test(path, name)
  if file_exists(path) then
    return
  end
  ensure_dir(path)
  local lines = {
    "import { mount } from \"@vue/test-utils\"",
    "import " .. name .. " from \"./" .. name .. ".vue\"",
    "",
    "describe(\"" .. name .. "\", () => {",
    "  it(\"renders\", () => {",
    "    const wrapper = mount(" .. name .. ")",
    "    expect(wrapper.exists()).toBe(true)",
    "  })",
    "})",
  }
  vim.fn.writefile(lines, path)
end

local function open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function project_root(start_dir)
  if vim.fs and vim.fs.find then
    local found = vim.fs.find(".git", { path = start_dir, upward = true })
    if found and found[1] then
      return vim.fn.fnamemodify(found[1], ":h")
    end
  end
  return vim.fn.getcwd()
end

local function search_repo_for_test(path)
  local root = project_root(vim.fn.fnamemodify(path, ":p:h"))
  local base = vim.fn.fnamemodify(path, ":t:r")
  local pattern = "**/" .. base .. ".spec.ts"
  local matches = vim.fn.globpath(root, pattern, false, true)
  if type(matches) ~= "table" then
    return {}
  end
  table.sort(matches)
  return matches
end

function M.open_or_create_test()
  local path = current_path()
  if not path then
    vim.notify("No file path for current buffer.", vim.log.levels.WARN)
    return
  end

  if not is_vue_file(path) then
    vim.notify("Not a Vue file.", vim.log.levels.WARN)
    return
  end

  local candidates = test_candidates(path)
  for _, candidate in ipairs(candidates) do
    if file_exists(candidate) then
      open_file(candidate)
      return
    end
  end

  local matches = search_repo_for_test(path)
  if #matches == 1 then
    open_file(matches[1])
    return
  elseif #matches > 1 then
    vim.ui.select(matches, {
      prompt = "Select test file",
      format_item = function(item)
        return vim.fn.fnamemodify(item, ":.")
      end,
    }, function(choice)
      if choice then
        open_file(choice)
      end
    end)
    return
  end

  local target = candidates[1]
  write_vue_test(target, component_name(path))
  open_file(target)
end

function M.setup()
  vim.api.nvim_create_user_command("VueTest", function()
    M.open_or_create_test()
  end, {})

  vim.keymap.set("n", "<leader>ct", function()
    M.open_or_create_test()
  end, { desc = "Create/open Vue test" })
end

return M
