-- ┌─────────────────────────────────────────────────────────────┐
-- │ LSP Server Configurations                                   │
-- │ Purpose: Define settings for each language server           │
-- │ Note: Only include non-default settings here               │
-- │ Servers are auto-installed by Mason                        │
-- └─────────────────────────────────────────────────────────────┘

local M = {}

local vue_language_server_path = vim.fn.stdpath("data")
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
local tsserver_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
}
local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

-- Server-specific configurations
-- Empty tables ({}) use default settings from nvim-lspconfig
M.server_configs = {
  -- === WEB DEVELOPMENT ===
  html = {},
  jsonls = {},
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
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts" })
      if root then
        on_dir(root)
      end
    end
  },
  
  -- === TYPESCRIPT/JAVASCRIPT ===
  vtsls = {
    filetypes = tsserver_filetypes,
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = { vue_plugin },
        },
      },
      typescript = {
        tsserver = {
          useSyntaxServer = false,
        },
        inlayHints = {
          includeInlayParameterNameHints = "all",
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
  
  -- === VUE ===
  vue_ls = {
    filetypes = { "vue" },
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
  
  -- === LUA ===
  lua_ls = {},
  
  -- === PYTHON ===
  pyright = {},
  pylsp = {},
  
  -- === RUBY ===
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
}

return M
