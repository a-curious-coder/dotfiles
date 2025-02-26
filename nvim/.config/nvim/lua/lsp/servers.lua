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
   -- Updated ts_ls config (remove vue from filetypes)
  ts_ls = {
    init_options = {
      plugins = {
        {
          name = "@vue/typescript-plugin",
          location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin",
          languages = { "vue" }
        }
      }
    },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" } -- REMOVE 'vue' here
  },

  -- Volar config (add takeover mode)
  volar = {
    filetypes = { 'vue', 'typescript', 'javascript' },
    init_options = {
      vue = {
        hybridMode = false -- Disable for full takeover[9]
      }
    }
  }
}

return M
