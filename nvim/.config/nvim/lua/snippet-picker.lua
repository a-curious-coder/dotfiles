local M = {}

local function normalize_text(value)
  if value == nil then
    return ""
  end
  if type(value) == "table" then
    return table.concat(value, ", ")
  end
  return tostring(value)
end

local function collect_snippets()
  local ls = require("luasnip")
  local available = ls.available(function(snip)
    return snip
  end)

  local items = {}
  for ft, snippets in pairs(available) do
    for _, snip in ipairs(snippets) do
      local trigger = normalize_text(snip.trigger)
      local name = normalize_text(snip.name)
      local desc = normalize_text(snip.description)
      table.insert(items, {
        snip = snip,
        ft = ft,
        trigger = trigger,
        name = name,
        desc = desc,
      })
    end
  end

  table.sort(items, function(a, b)
    local a_key = (a.trigger ~= "" and a.trigger or a.name) .. a.ft
    local b_key = (b.trigger ~= "" and b.trigger or b.name) .. b.ft
    return a_key < b_key
  end)

  return items
end

local function format_item(item)
  local trigger = item.trigger ~= "" and item.trigger or "(no trigger)"
  local label = item.name ~= "" and item.name or item.desc
  if label == "" then
    label = "Snippet"
  end
  return string.format("%s — %s [%s]", trigger, label, item.ft)
end

local function expand_snippet(item)
  if not item or not item.snip then
    return
  end
  require("luasnip").snip_expand(item.snip)
end

local function open_with_telescope(items)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return false
  end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "Insert snippet",
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            display = format_item(item),
            ordinal = table.concat({
              item.trigger,
              item.name,
              item.desc,
              item.ft,
            }, " "),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          local snip = entry.value.snip
          local lines = {}
          if snip and snip.get_docstring then
            lines = snip:get_docstring() or {}
          end
          if type(lines) == "string" then
            lines = vim.split(lines, "\n")
          end
          if #lines == 0 then
            lines = { "(no preview)" }
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          local ft = entry.value.ft
          if ft and ft ~= "all" then
            vim.bo[self.state.bufnr].filetype = ft
          else
            vim.bo[self.state.bufnr].filetype = "text"
          end
        end,
      }),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            expand_snippet(selection.value)
          end
        end)
        return true
      end,
    })
    :find()

  return true
end

function M.open()
  local items = collect_snippets()
  if #items == 0 then
    vim.notify("No snippets available for this filetype.", vim.log.levels.WARN)
    return
  end

  if open_with_telescope(items) then
    return
  end

  vim.ui.select(items, {
    prompt = "Insert snippet",
    format_item = format_item,
  }, function(choice)
    expand_snippet(choice)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("SnipPick", function()
    M.open()
  end, {})

  vim.keymap.set("n", "<leader>ss", function()
    M.open()
  end, { desc = "Snippet: Insert" })
end

return M
