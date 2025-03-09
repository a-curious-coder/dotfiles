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
          name = '@vue/typescript-plugin',
          location = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
          languages = { 'vue' },
        },
      },
    },
    settings = {
      typescript = {
        tsserver = {
          useSyntaxServer = false,
        },
        inlayHints = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },
  -- Volar config (add takeover mode)
  volar = {
    init_options = {
      vue = {
        hybridMode = false,
      },
    },
    settings = {
      typescript = {
        inlayHints = {
          enumMemberValues = {
            enabled = true,
          },
          functionLikeReturnTypes = {
            enabled = true,
          },
          propertyDeclarationTypes = {
            enabled = true,
          },
          parameterTypes = {
            enabled = true,
            suppressWhenArgumentMatchesName = true,
          },
          variableTypes = {
            enabled = true,
          },
        },
      },
      html = {
        format = {
          wrapAttributes = "force-expand-multiline",
        },
      },
    },
  },
}

return M
