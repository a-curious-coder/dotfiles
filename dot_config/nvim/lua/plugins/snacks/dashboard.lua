return {
	sections = {
		{ section = "header" },
		{ section = "keys" },
		{
			pane = 2,
			section = "terminal",
			cmd = "ascii-image-converter aaw.png -C -c ",
			height = 25,
			padding = 1,
		},
		{
			pane = 2,
			icon = " ",
			desc = "Browse Repo",
			padding = 1,
			key = "b",
			action = function()
				Snacks.gitbrowse()
			end,
		},
		function()
			local in_git = Snacks.git.get_root() ~= nil
			local cmds = {
				{
					icon = " ",
					title = "Open PRs",
					cmd = "gh pr list --limit 3",
					key = "p",
					action = function()
						vim.fn.jobstart("gh pr list --web", { detach = true })
					end,
				},
				{
					icon = " ",
					section = "terminal",
					title = "Git Status",
					cmd = "git diff --stat",
				},
			}
			return vim.tbl_map(function(cmd)
				return vim.tbl_extend("force", {
					pane = 2,
					section = "terminal",
					enabled = in_git,
					--padding = 1,
					ttl = 5 * 60,
					indent = 3,
				}, cmd)
			end, cmds)
		end,
		{ section = "startup" },
	},
}
