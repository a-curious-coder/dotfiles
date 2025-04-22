return {
  "ahmedkhalf/project.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("project_nvim").setup({
      -- Detection methods: lsp, pattern, git
      detection_methods = { "pattern", "lsp", "git" },
      
      -- Patterns to detect project root
      patterns = {
        ".git", "Makefile", "package.json", "Cargo.toml",
        ".ruby-version", "go.mod", "requirements.txt"
      },
      
      -- Show hidden files
      show_hidden = true,
      
      -- Don't automatically change directory
      manual_mode = false,
      
      -- Silent mode
      silent_chdir = true,
      
      -- Update the cwd on project change
      update_cwd = true,
      
      -- Update workspaces automatically
      update_focused_file = {
        enable = true,
        update_cwd = true
      },
    })
    
    -- Integrate with telescope
    require('telescope').load_extension('projects')
    
    -- Keybinding to list projects
    vim.keymap.set(
      "n",
      "<leader>fp",
      function() require('telescope').extensions.projects.projects() end,
      { desc = "Find projects" }
    )
  end
}