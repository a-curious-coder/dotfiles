local M = {}

local templates = {
  { label = "Vue component + Jest test (TS, co-located)", kind = "vue_component_with_test" },
  { label = "Vue component (TS, <script setup>)", kind = "vue_component" },
  { label = "Vue composable + Jest test (TS)", kind = "vue_composable_with_test" },
  { label = "Vue composable (TS)", kind = "vue_composable" },
  { label = "TypeScript module + Jest test", kind = "ts_module_with_test" },
  { label = "Jest test (TS)", kind = "jest_test" },
}

local function current_base_dir()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end
  return vim.fn.getcwd()
end

local function normalize_name(input)
  local name = vim.trim(input or "")
  if name == "" then
    return nil
  end
  name = name:gsub("%.spec%.tsx$", "")
  name = name:gsub("%.test%.tsx$", "")
  name = name:gsub("%.spec%.ts$", "")
  name = name:gsub("%.test%.ts$", "")
  name = name:gsub("%.spec%.js$", "")
  name = name:gsub("%.test%.js$", "")
  name = name:gsub("%.tsx$", "")
  name = name:gsub("%.ts$", "")
  name = name:gsub("%.jsx$", "")
  name = name:gsub("%.js$", "")
  name = name:gsub("%.vue$", "")
  return name
end

local function to_identifier(name)
  local base = name:gsub(".*/", "")
  base = base:gsub("[^%w]+", " ")
  base = base:gsub("(%a)([%w]*)", function(first, rest)
    return first:upper() .. rest
  end)
  base = base:gsub("%s+", "")
  if base == "" then
    base = "Component"
  end
  if base:match("^%d") then
    base = "Component" .. base
  end
  return base
end

local function to_camel(name)
  local ident = to_identifier(name)
  return ident:sub(1, 1):lower() .. ident:sub(2)
end

local function to_use_function(name)
  local ident = to_identifier(name)
  if ident:match("^Use[A-Z]") then
    return "use" .. ident:sub(4)
  end
  return "use" .. ident
end

local function to_kebab(name)
  local base = name:gsub(".*/", "")
  base = base:gsub("(%l)(%u)", "%1-%2")
  base = base:gsub("[_%s]+", "-")
  base = base:gsub("[^%w-]", "")
  base = base:gsub("-+", "-")
  return base:lower()
end

local function ensure_dir(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function write_file(path, lines)
  if vim.fn.filereadable(path) == 1 then
    return false
  end
  ensure_dir(path)
  vim.fn.writefile(lines, path)
  return true
end

local function resolve_path(base_dir, name, ext)
  local path = name
  if not name:match("^/") and not name:match("^~") then
    path = base_dir .. "/" .. name
  else
    path = vim.fn.expand(name)
  end
  if ext ~= "" and not path:match("%.[^/]+$") then
    path = path .. "." .. ext
  end
  return vim.fn.fnamemodify(path, ":p")
end

local function open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function open_split(path)
  vim.cmd("vsplit " .. vim.fn.fnameescape(path))
end

local function ensure_ui_select()
  local ok, telescope = pcall(require, "telescope")
  if ok then
    pcall(telescope.load_extension, "ui-select")
  end
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

local function relative_to_root(path, root)
  local full = vim.fn.fnamemodify(path, ":p")
  local base = vim.fn.fnamemodify(root, ":p")
  if base:sub(-1) ~= "/" then
    base = base .. "/"
  end
  if full:sub(1, #base) == base then
    return full:sub(#base + 1)
  end
  return full
end

local function find_existing_tests(name, base_dir, root)
  local base = vim.fn.fnamemodify(name, ":t")
  local local_name = name
  local candidates = {
    resolve_path(base_dir, local_name .. ".spec", "ts"),
    resolve_path(base_dir, local_name .. ".test", "ts"),
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return { path }
    end
  end

  local variants = {
    base,
    to_identifier(base),
    to_kebab(base),
  }
  local suffixes = {
    "spec.ts",
    "test.ts",
    "spec.tsx",
    "test.tsx",
    "spec.js",
    "test.js",
  }

  local results = {}
  local seen = {}
  for _, variant in ipairs(variants) do
    for _, suffix in ipairs(suffixes) do
      local pattern = "**/" .. variant .. "." .. suffix
      local matches = vim.fn.globpath(root, pattern, false, true)
      for _, path in ipairs(matches) do
        if not seen[path] and not path:find("/node_modules/") and not path:find("/%.git/") then
          seen[path] = true
          table.insert(results, path)
        end
      end
    end
  end

  table.sort(results)
  return results
end

local function open_existing_test(paths, root, in_split)
  if #paths == 0 then
    return false
  end

  local function open_path(path)
    if in_split then
      open_split(path)
    else
      open_file(path)
    end
  end

  if #paths == 1 then
    open_path(paths[1])
    return true
  end

  vim.ui.select(paths, {
    prompt = "Open existing test",
    format_item = function(item)
      return relative_to_root(item, root)
    end,
  }, function(choice)
    if choice then
      open_path(choice)
    end
  end)
  return true
end

local function vue_component_template(name)
  local class_name = to_kebab(name)
  return {
    "<template>",
    "  <div class=\"" .. class_name .. "\">",
    "    <!-- TODO: content -->",
    "  </div>",
    "</template>",
    "",
    "<script setup lang=\"ts\">",
    "</script>",
    "",
    "<style scoped>",
    "</style>",
  }
end

local function vue_test_template(name, component_path)
  local component_id = to_identifier(name)
  local relative = "./" .. vim.fn.fnamemodify(component_path, ":t")
  return {
    "import { mount } from \"@vue/test-utils\"",
    "import " .. component_id .. " from \"" .. relative .. "\"",
    "",
    "describe(\"" .. component_id .. "\", () => {",
    "  it(\"renders\", () => {",
    "    const wrapper = mount(" .. component_id .. ")",
    "    expect(wrapper.exists()).toBe(true)",
    "  })",
    "})",
  }
end

local function vue_composable_template(name)
  local func_name = to_use_function(name)
  return {
    "import { ref } from \"vue\"",
    "",
    "export function " .. func_name .. "() {",
    "  const state = ref(null as null | unknown)",
    "",
    "  return {",
    "    state,",
    "  }",
    "}",
  }
end

local function ts_module_template(name)
  local func_name = to_camel(name)
  return {
    "export function " .. func_name .. "() {",
    "  return true",
    "}",
  }
end

local function jest_test_template(name)
  local test_name = to_identifier(name)
  return {
    "describe(\"" .. test_name .. "\", () => {",
    "  it(\"works\", () => {",
    "    expect(true).toBe(true)",
    "  })",
    "})",
  }
end

local function create_vue_files(name, with_test)
  local base_dir = current_base_dir()
  local root = project_root(base_dir)
  local component_path = resolve_path(base_dir, name, "vue")
  local test_path = resolve_path(base_dir, name .. ".spec", "ts")

  local created_component = write_file(component_path, vue_component_template(name))
  local created_test = false
  local existing_tests = {}
  if with_test then
    existing_tests = find_existing_tests(name, base_dir, root)
    if #existing_tests == 0 then
      created_test = write_file(test_path, vue_test_template(name, component_path))
    end
  end

  if not created_component then
    vim.notify("File exists: " .. component_path, vim.log.levels.WARN)
  end
  if with_test and not created_test and #existing_tests == 0 then
    vim.notify("File exists: " .. test_path, vim.log.levels.WARN)
  end

  open_file(component_path)
  if with_test then
    if #existing_tests > 0 then
      open_existing_test(existing_tests, root, true)
    elseif created_test then
      open_split(test_path)
    end
  end
end

local function create_jest_test(name)
  local base_dir = current_base_dir()
  local root = project_root(base_dir)
  local existing_tests = find_existing_tests(name, base_dir, root)
  if #existing_tests > 0 then
    open_existing_test(existing_tests, root, false)
    return
  end
  local test_path = resolve_path(base_dir, name .. ".spec", "ts")
  local created = write_file(test_path, jest_test_template(name))
  if not created then
    vim.notify("File exists: " .. test_path, vim.log.levels.WARN)
  end
  open_file(test_path)
end

local function create_composable(name, with_test)
  local base_dir = current_base_dir()
  local root = project_root(base_dir)
  local file_path = resolve_path(base_dir, name, "ts")
  local test_path = resolve_path(base_dir, name .. ".spec", "ts")

  local created_file = write_file(file_path, vue_composable_template(name))
  local created_test = false
  local existing_tests = {}
  if with_test then
    existing_tests = find_existing_tests(name, base_dir, root)
    if #existing_tests == 0 then
      created_test = write_file(test_path, jest_test_template(name))
    end
  end

  if not created_file then
    vim.notify("File exists: " .. file_path, vim.log.levels.WARN)
  end
  if with_test and not created_test and #existing_tests == 0 then
    vim.notify("File exists: " .. test_path, vim.log.levels.WARN)
  end

  open_file(file_path)
  if with_test then
    if #existing_tests > 0 then
      open_existing_test(existing_tests, root, true)
    elseif created_test then
      open_split(test_path)
    end
  end
end

local function create_ts_module(name, with_test)
  local base_dir = current_base_dir()
  local root = project_root(base_dir)
  local file_path = resolve_path(base_dir, name, "ts")
  local test_path = resolve_path(base_dir, name .. ".spec", "ts")

  local created_file = write_file(file_path, ts_module_template(name))
  local created_test = false
  local existing_tests = {}
  if with_test then
    existing_tests = find_existing_tests(name, base_dir, root)
    if #existing_tests == 0 then
      created_test = write_file(test_path, jest_test_template(name))
    end
  end

  if not created_file then
    vim.notify("File exists: " .. file_path, vim.log.levels.WARN)
  end
  if with_test and not created_test and #existing_tests == 0 then
    vim.notify("File exists: " .. test_path, vim.log.levels.WARN)
  end

  open_file(file_path)
  if with_test then
    if #existing_tests > 0 then
      open_existing_test(existing_tests, root, true)
    elseif created_test then
      open_split(test_path)
    end
  end
end

function M.prompt()
  ensure_ui_select()
  vim.ui.select(templates, {
    prompt = "Create file",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.ui.input({ prompt = "Name (relative to current file): " }, function(input)
      local name = normalize_name(input)
      if not name then
        return
      end
      if choice.kind == "vue_component_with_test" then
        create_vue_files(name, true)
      elseif choice.kind == "vue_component" then
        create_vue_files(name, false)
      elseif choice.kind == "vue_composable_with_test" then
        create_composable(name, true)
      elseif choice.kind == "vue_composable" then
        create_composable(name, false)
      elseif choice.kind == "ts_module_with_test" then
        create_ts_module(name, true)
      elseif choice.kind == "jest_test" then
        create_jest_test(name)
      end
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("NewFile", function()
    M.prompt()
  end, {})

  vim.keymap.set("n", "<leader>cn", function()
    M.prompt()
  end, { desc = "Create file from template" })
end

return M
