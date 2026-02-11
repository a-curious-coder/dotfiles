local M = {}

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local content = table.concat(lines, "\n")
  local ok_decode, data = pcall(vim.fn.json_decode, content)
  if not ok_decode then
    return nil
  end
  return data
end

local function collect_all_snippets()
  local config = require("scissors.config").config
  local convert = require("scissors.vscode-format.convert-object")
  local u = require("scissors.utils")
  local snippet_dir = config.snippetDir

  local package_path = snippet_dir .. "/package.json"
  if not u.fileExists(package_path) then
    u.notify("Snippet package.json not found in " .. snippet_dir, "warn")
    return {}
  end

  local pkg = read_json(package_path)
  if type(pkg) ~= "table" then
    u.notify("Unable to read snippet package.json", "error")
    return {}
  end

  local contributes = pkg.contributes or {}
  local entries = contributes.snippets or {}
  local all_snippets = {}
  local seen = {}

  for _, entry in ipairs(entries) do
    local languages = entry.language
    if type(languages) == "string" then
      languages = { languages }
    end
    if type(languages) == "table" and entry.path then
      local rel = entry.path:gsub("^%.?/", "")
      local abs = snippet_dir .. "/" .. rel
      if u.fileExists(abs) then
        for _, ft in ipairs(languages) do
          local key = ft .. "\0" .. abs
          if not seen[key] then
            local snippets = convert.readVscodeSnippetFile(abs, ft)
            vim.list_extend(all_snippets, snippets)
            seen[key] = true
          end
        end
      else
        u.notify("Snippet file missing: " .. rel, "warn")
      end
    end
  end

  return all_snippets
end

function M.open()
  local snippets = collect_all_snippets()
  if #snippets == 0 then
    vim.notify("No snippets found.", vim.log.levels.WARN)
    return
  end

  require("scissors.2-picker.picker-choice").selectSnippet(snippets)
end

function M.setup()
  vim.api.nvim_create_user_command("SnipEditAll", function()
    M.open()
  end, {})

  vim.keymap.set("n", "<leader>sE", function()
    M.open()
  end, { desc = "Snippet: Edit all" })
end

return M
