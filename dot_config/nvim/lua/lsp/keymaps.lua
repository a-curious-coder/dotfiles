local M = {}

M.setup = function(bufnr)
    local opts = { buffer = bufnr }
    
    -- Basic LSP keymaps
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    
    -- Additional useful keymaps
    vim.keymap.set("n", "<leader>ls", ":LspInfo<CR>", opts)
    vim.keymap.set("n", "<leader>ll", ":LspLog<CR>", opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
end

return M 