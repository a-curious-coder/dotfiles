return {
  "natecraddock/workspaces.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("workspaces").setup({
      hooks = {
        open = { "Telescope find_files" }
      }
    })
    
    -- Add workspace commands to telescope
    require("telescope").load_extension("workspaces")
    
    -- Keybindings
    vim.keymap.set("n", "<leader>wa", function() require("workspaces").add() end, { desc = "Add workspace" })
    vim.keymap.set("n", "<leader>wr", function() require("workspaces").remove() end, { desc = "Remove workspace" })
    vim.keymap.set("n", "<leader>wl", function() require("telescope").extensions.workspaces.workspaces() end, { desc = "List workspaces" })
  end
}
