return {
  "rhysd/conflict-marker.vim",
  -- Load before syntax files so the plugin's after/syntax can attach
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local function set_conflict_marker_highlights()
      local highlights = {
        -- Marker lines: strong contrast for readability
        ConflictMarkerBegin = { fg = "#fef2f2", bg = "#7f1d1d", bold = true },
        ConflictMarkerOurs = { fg = "#ecfdf3", bg = "#14532d", bold = true },
        ConflictMarkerCommonAncestors = { fg = "#eff6ff", bg = "#1e3a8a", bold = true },
        ConflictMarkerSeparator = { fg = "#fffbeb", bg = "#78350f", bold = true },
        ConflictMarkerTheirs = { fg = "#e0f2fe", bg = "#1e40af", bold = true },
        ConflictMarkerEnd = { fg = "#f9fafb", bg = "#374151", bold = true },

        -- Hunk lines: subtle background, keep syntax colors
        ConflictMarkerOursHunk = { bg = "#10251b" },
        ConflictMarkerTheirsHunk = { bg = "#101c2b" },
        ConflictMarkerCommonAncestorsHunk = { bg = "#1c1f2a" },
      }

      for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end

    set_conflict_marker_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("conflict-marker-highlights", { clear = true }),
      callback = set_conflict_marker_highlights,
      desc = "Keep conflict marker highlights visible after colorscheme changes",
    })
  end,
}
