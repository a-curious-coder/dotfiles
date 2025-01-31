local M = {}

-- Timeout for LSP startup (in milliseconds)
M.startup_timeout = 5000

-- Function to check if LSP is ready with timeout
M.wait_for_lsp_attach = function(timeout)
    local timer = vim.loop.new_timer()
    local start_time = vim.loop.now()
    
    timer:start(0, 100, vim.schedule_wrap(function()
        local clients = vim.lsp.get_active_clients()
        local current_time = vim.loop.now()
        
        if #clients > 0 then
            vim.notify("LSP attached successfully!", vim.log.levels.INFO)
            timer:stop()
        elseif current_time - start_time > timeout then
            vim.notify("LSP attachment timed out!", vim.log.levels.WARN)
            timer:stop()
        end
    end))
end

-- Enhanced notification with more details
M.notify_lsp_status = function(client, bufnr)
    local msg = string.format(
        "LSP: %s\nStatus: Ready\nBuffer: %d\nCapabilities: %d",
        client.name,
        bufnr,
        vim.tbl_count(client.server_capabilities)
    )
    vim.notify(msg, vim.log.levels.INFO, {
        title = "LSP Status",
        timeout = 2000
    })
end

return M 