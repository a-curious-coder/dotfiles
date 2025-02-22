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
  tailwindcss = {
    filetypes = {
      "html", "vue", "javascriptreact",
      "typescriptreact", "svelte", "astro"
    },
    init_options = {
      userLanguages = {
        vue = "html"
      }
    },
    root_dir = function(fname)
      return require("lspconfig").util.root_pattern("tailwind.config.js", "tailwind.config.cjs")(fname)
    end
  },
  volar = {},
  ts_ls = {
    init_options = {
      plugins = {
        {
          name = "@vue/typescript-plugin",
          location = "/root/.nvm/versions/node/v23.6.1/lib",
          languages = { "vue" },
        },
      },
    },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  }
}

return M
