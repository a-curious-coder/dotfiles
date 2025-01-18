local M = {}

M.server_configs = {
    html = {},
    jsonls = {},
    lua_ls = {},
    pyright = {},
    pylsp = {},
    ruby_lsp = {
        cmd = { "ruby-lsp" },
        settings = {
            rubocop = {
                enable = true,
                lint = true,
                format = true
            }
        }
    },
    tailwindcss = {}
}

return M 