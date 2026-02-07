-- ┌─────────────────────────────────────────────────────────────┐
-- │ LSP Keymaps                                                 │
-- │ Purpose: Define consistent keybindings for all LSP servers  │
-- │ Applied to: Every buffer with an attached LSP server        │
-- └─────────────────────────────────────────────────────────────┘

local M = {}

local function get_hover_lines(callback)
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/hover", params, function(err, result, _, _)
    if err or not (result and result.contents) then
      return
    end

    local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
    if vim.tbl_isempty(markdown_lines) then
      return
    end

    callback(markdown_lines)
  end)
end

local function hover_float()
  get_hover_lines(function(lines)
    local bufnr, winnr = vim.lsp.util.open_floating_preview(lines, "markdown", {
      border = "rounded",
      focusable = true,
      focus_id = "hover",
      max_width = math.floor(vim.o.columns * 0.7),
      max_height = math.floor(vim.o.lines * 0.8),
    })

    if winnr and vim.api.nvim_win_is_valid(winnr) then
      vim.wo[winnr].wrap = true
      vim.wo[winnr].linebreak = true
    end
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = bufnr, silent = true, nowait = true })
      vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = bufnr, silent = true, nowait = true })
    end
  end)
end

local function hover_split()
  get_hover_lines(function(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    vim.cmd("botright vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].conceallevel = 2

    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
  end)
end

M.setup = function(bufnr)
  local opts = { buffer = bufnr }

  -- === CORE LSP ACTIONS ===
  vim.keymap.set("n", "K", hover_float, vim.tbl_extend("force", opts, { desc = "Show hover documentation" }))
  vim.keymap.set("n", "<leader>k", hover_split, vim.tbl_extend("force", opts, { desc = "Show hover documentation (split)" }))
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
  vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Show references" }))
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code actions" }))
  vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

  -- === DIAGNOSTICS ===
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
  vim.keymap.set("n", "gl", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

  -- Note: Formatting is handled by Conform plugin (<leader>cf in conform.lua)
end

return M
