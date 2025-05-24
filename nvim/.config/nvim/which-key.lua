return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,

  config = function()
    local wk = require("which-key")

    local config = {
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
      },

      win = {
        border = "single",
        position = "bottom",
      },

      layout = {
        spacing = 6,
        align = "center",
      },

      -- Replace deprecated options with new filter option
      filter = function(prefix)
        -- Handle if prefix is a table (mapping entry)
        if type(prefix) == "table" then
          prefix = prefix[1] or ""
        end
        
        -- Ensure prefix is a string
        prefix = tostring(prefix)
        
        local patterns = {
          "^silent", "^cmd", "^Cmd", "^CR",
          "^:", "^ ", "^call ", "^lua "
        }
        for _, pattern in ipairs(patterns) do
          if string.find(prefix, pattern) then
            return false
          end
        end
        return true
      end,

      show_help = true,
    }

    wk.setup(config)

    -- Register mappings with the new format
    local mappings = {
      ["<leader>"] = {
        b = { name = "Buffers" },
        c = { name = "Code" },
        d = { name = "Debug" },
        f = { 
          name = "Find/Files",
          p = { 
            name = "Projects",
            ["<space>"] = { name = "Find projects" }
          }
        },
        g = { name = "Git" },
        t = { name = "Tests" },
        u = { name = "UI" },
        w = { name = "Workspace" },
      },
      g = {
        name = "Go/LSP",
        ["%"] = { name = "Cycle results" },
        O = { name = "Document symbols" },
        c = { 
          name = "Comments",
          c = { name = "Toggle line" }
        },
        r = {
          name = "References",
          a = { name = "Code action" },
          i = { name = "Implementation" },
          n = { name = "Rename" },
          r = { name = "Find references" }
        },
        x = { name = "Open under cursor" }
      }
    }

    -- Register all mappings
    wk.register(mappings)
  end
}
