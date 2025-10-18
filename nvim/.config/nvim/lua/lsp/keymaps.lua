-- ┌─────────────────────────────────────────────────────────────┐
-- │ LSP Keymaps                                                 │
-- │ Purpose: Define consistent keybindings for all LSP servers  │
-- │ Applied to: Every buffer with an attached LSP server        │
-- └─────────────────────────────────────────────────────────────┘

local M = {}

M.setup = function(bufnr)
  local opts = { buffer = bufnr }

  -- === CORE LSP ACTIONS ===
  vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show hover documentation" }))
  vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
  vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Show references" }))
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code actions" }))
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

  -- === DIAGNOSTICS ===
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
  vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

  -- === LSP INFO ===
  vim.keymap.set("n", "<leader>ls", ":LspInfo<CR>", vim.tbl_extend("force", opts, { desc = "LSP info" }))
  vim.keymap.set("n", "<leader>ll", ":LspLog<CR>", vim.tbl_extend("force", opts, { desc = "LSP log" }))
  
  -- Note: Formatting is handled by Conform plugin (<leader>f in conform.lua)
end

return M

