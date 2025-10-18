-- ┌─────────────────────────────────────────────────────────────┐
-- │ LSP Utilities                                               │
-- │ Purpose: Helper functions for LSP configuration             │
-- │ Usage: Shared utilities used across LSP setup              │
-- └─────────────────────────────────────────────────────────────┘

local M = {}

-- Simple LSP status notification (only shows once, not spammy)
-- Only notifies when vim.g.lsp_debug is enabled to avoid spam
M.notify_lsp_status = function(client, bufnr)
  if vim.g.lsp_debug then
    local msg = string.format("LSP: %s attached to buffer %d", client.name, bufnr)
    vim.notify(msg, vim.log.levels.INFO, { timeout = 1000 })
  end
end

return M

