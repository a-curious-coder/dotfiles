-- Autosave on edit and focus changes
local function autosave_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].buftype ~= "" then return end
  if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then return end
  if vim.api.nvim_buf_get_name(bufnr) == "" then return end
  if not vim.bo[bufnr].modified then return end
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent! update")
  end)
end

vim.api.nvim_create_autocmd(
  { "TextChanged", "InsertLeave", "CursorHoldI", "FocusLost", "BufLeave" },
  {
    group = vim.api.nvim_create_augroup("autosave-on-edit", { clear = true }),
    callback = function(args) autosave_buffer(args.buf) end,
  }
)

-- Show tabline only when multiple buffers are open
local function update_tabline_visibility()
  local count = #vim.fn.getbufinfo({ buflisted = 1 })
  vim.opt.showtabline = count > 1 and 2 or 0
end
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("tabline-visibility", { clear = true }),
  callback = update_tabline_visibility,
})
update_tabline_visibility()

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- gf follows [[wikilinks]] in markdown (Obsidian-style)
local function find_wikilink_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local start = 1
  while true do
    local open_start, open_end = line:find("%[%[", start)
    if not open_start then return nil end
    local close_start, close_end = line:find("%]%]", open_end + 1)
    if not close_start then return nil end
    if col >= open_start and col <= close_end then
      return line:sub(open_end + 1, close_start - 1)
    end
    start = close_end + 1
  end
end

local function split_wikilink_target(raw)
  local target = (raw:gsub("^%s+", ""):gsub("%s+$", ""))
  target = target:match("^[^|]+") or target
  local file_part, anchor = target:match("^(.-)#(.+)$")
  if file_part == nil then file_part = target end
  if file_part == "" then file_part = nil end
  return file_part, anchor
end

local function resolve_wikilink_path(file_part)
  if not file_part then return vim.api.nvim_buf_get_name(0) end
  local target = file_part
  if not target:match("%.[^/\\]+$") then target = target .. ".md" end
  local full_path
  if target:sub(1, 1) == "/" then
    full_path = vim.fn.fnamemodify(vim.fn.getcwd() .. target, ":p")
  elseif target:match("^%a:[/\\]") then
    full_path = target
  else
    full_path = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. target, ":p")
  end
  if vim.fn.filereadable(full_path) == 1 then return full_path end
  return nil
end

local function jump_to_anchor(anchor)
  if not anchor or anchor == "" then return end
  local trimmed = anchor:gsub("^%s+", ""):gsub("%s+$", "")
  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if trimmed:sub(1, 1) == "^" and line:find(trimmed, 1, true) then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
    local heading = line:match("^#+%s*(.-)%s*$")
    if heading and heading == trimmed then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
  end
end

local function follow_wikilink_under_cursor()
  local raw = find_wikilink_under_cursor()
  if not raw then
    vim.cmd.normal({ args = { "gf" }, bang = true })
    return
  end
  local file_part, anchor = split_wikilink_target(raw)
  local path = resolve_wikilink_path(file_part)
  if not path then
    vim.notify("Wikilink target not found: " .. (file_part or raw), vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  jump_to_anchor(anchor)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown-wikilinks", { clear = true }),
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "gf", follow_wikilink_under_cursor, {
      buffer = ev.buf,
      desc = "Follow file or wikilink",
    })
  end,
})
