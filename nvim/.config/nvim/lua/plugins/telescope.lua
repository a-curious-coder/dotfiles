-- ┌─────────────────────────────────────────────────────────────┐
-- │ Telescope - Fuzzy Finder                                    │
-- │ Purpose: Fast file/text searching and navigation            │
-- │ Dependencies: ripgrep (for grep), fd (optional for speed)    │
-- └─────────────────────────────────────────────────────────────┘

return {
	-- Extension: Better UI for selections
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},

	-- Extension: FZF native for better performance
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},

	-- Main Telescope plugin
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local builtin = require("telescope.builtin")
			local tutils = require("telescope.utils")
			local make_entry = require("telescope.make_entry")

			local fd_cmd = nil
			local fd_bin = nil

			if vim.fn.executable("fd") == 1 then
				fd_bin = "fd"
			elseif vim.fn.executable("fdfind") == 1 then
				fd_bin = "fdfind"
			end

			if fd_bin then
				fd_cmd = { fd_bin, "--type", "f", "--hidden", "--exclude", ".git" }
			else
				if not vim.g._telescope_fd_notice then
					vim.g._telescope_fd_notice = true
					vim.schedule(function()
						vim.notify("Telescope: install `fd` for faster file searching.", vim.log.levels.INFO)
					end)
				end
			end

			if vim.fn.executable("rg") == 0 then
				if not vim.g._telescope_rg_notice then
					vim.g._telescope_rg_notice = true
					vim.schedule(function()
						vim.notify("Telescope: install `rg` (ripgrep) for live grep.", vim.log.levels.WARN)
					end)
				end
			end

			local defaults = {
				file_ignore_patterns = {
					"%.git/", -- Still ignore .git directory to avoid clutter
					"node_modules/",
					"%.DS_Store",
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<Esc>"] = actions.close, -- Close with single Escape
						["<C-u>"] = false, -- Disable default scroll up to allow history navigation
						["<C-d>"] = false, -- Disable default scroll down
					},
					n = {
						["q"] = actions.close, -- Close with q in normal mode
					},
				},
				path_display = { "truncate" }, -- Default path display (overridden per picker)
				sorting_strategy = "ascending", -- Show results from top to bottom
				layout_config = {
					horizontal = {
						prompt_position = "top", -- Prompt at the top
						preview_width = 0.55, -- Wider preview
					},
				},
			}

			if fd_cmd then
				defaults.find_command = fd_cmd
			end

			telescope.setup({
				defaults = defaults,
				pickers = {
					find_files = {
						theme = "dropdown",
						hidden = true, -- Show hidden files
					},
					live_grep = {
						additional_args = function()
							return { "--hidden" } -- Show hidden files in grep results
						end,
					},
					grep_string = {
						additional_args = function()
							return { "--hidden" } -- Show hidden files in grep_string
						end,
					},
					buffers = {
						show_all_buffers = true,
						sort_lastused = true,
						theme = "dropdown",
						mappings = {
							i = {
								["<C-d>"] = actions.delete_buffer,
							},
							n = {
								["dd"] = actions.delete_buffer,
							},
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})

			local function load_extension_if_available(name)
				local ok = pcall(telescope.load_extension, name)
				if ok then
					return
				end

				local key = "_telescope_extension_notice_" .. name
				if vim.g[key] then
					return
				end
				vim.g[key] = true
				vim.schedule(function()
					vim.notify("Telescope extension unavailable: " .. name, vim.log.levels.DEBUG)
				end)
			end

			-- Load extensions
			load_extension_if_available("ui-select")
			load_extension_if_available("fzf") -- Much faster fuzzy finding

			local function project_root()
				local buf = vim.api.nvim_buf_get_name(0)
				local start_dir = buf ~= "" and vim.fn.fnamemodify(buf, ":p:h") or vim.fn.getcwd()
				local output = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })
				if vim.v.shell_error == 0 and output[1] and output[1] ~= "" then
					return output[1]
				end
				return vim.fn.getcwd()
			end

			local function is_repo_scope()
				if vim.g.telescope_scope_mode == nil then
					vim.g.telescope_scope_mode = "repo"
				end
				return vim.g.telescope_scope_mode == "repo"
			end

			local function relative_path(path, root)
				if not path or path == "" then
					return path
				end
				if not path:match("^/") then
					return path
				end
				if not root or root == "" then
					return path
				end
				local r = vim.fn.fnamemodify(root, ":p")
				if r:sub(-1) ~= "/" then
					r = r .. "/"
				end
				local p = vim.fn.fnamemodify(path, ":p")
				if p:sub(1, #r) == r then
					return p:sub(#r + 1)
				end
				return path
			end

			local function scope_opts()
				local root = project_root()
				local scoped = is_repo_scope()
				local cwd = scoped and root or nil
				local display_root = scoped and root or vim.fn.getcwd()
				return {
					cwd = cwd,
					display_root = display_root,
				}
			end

			local function toggle_scope()
				vim.g.telescope_scope_mode = is_repo_scope() and "global" or "repo"
				vim.notify("Telescope scope: " .. vim.g.telescope_scope_mode, vim.log.levels.INFO)
			end

			local function format_filename(path, root)
				local tail = tutils.path_tail(path)
				local rel = relative_path(path, root)
				local dir = rel:gsub(tail .. "$", ""):gsub("/$", "")
				if dir == "" then
					return tail, nil, nil
				end
				local sep = " — "
				local display = tail .. sep .. dir
				local start = #tail
				local finish = #display
				return display, start, finish
			end

			local function apply_highlights(filename, display, start, finish, opts)
				local icon_display, icon_hl, icon = tutils.transform_devicons(filename, display, opts.disable_devicons)
				local highlights = {}
				if icon_hl then
					table.insert(highlights, { { 0, #icon }, icon_hl })
				end
				if start and finish then
					local offset = icon and (#icon + 1) or 0
					table.insert(highlights, { { offset + start, offset + finish }, "TelescopeResultsComment" })
				end
				return icon_display, highlights
			end

			local function file_entry_maker(opts)
				local entry_maker = make_entry.gen_from_file(opts)
				return function(line)
					local entry = entry_maker(line)
					entry.display = function(e)
						local display, start, finish = format_filename(e.value, opts.display_root)
						return apply_highlights(e.value, display, start, finish, opts)
					end
					return entry
				end
			end

			local function vimgrep_entry_maker(opts)
				local entry_maker = make_entry.gen_from_vimgrep(opts)
				return function(line)
					local entry = entry_maker(line)
					entry.display = function(e)
						local display_filename, start, finish = format_filename(e.filename, opts.display_root)
						local coordinates = ":"
						if not opts.disable_coordinates then
							if e.lnum then
								if e.col then
									coordinates = string.format(":%s:%s:", e.lnum, e.col)
								else
									coordinates = string.format(":%s:", e.lnum)
								end
							end
						end
						local display = string.format("%s%s%s", display_filename, coordinates, e.text or "")
						return apply_highlights(e.filename, display, start, finish, opts)
					end
					return entry
				end
			end

			local function recent_files_picker()
				local opts = scope_opts()
				builtin.oldfiles(vim.tbl_extend("force", opts, {
					cwd_only = is_repo_scope(),
				}))
			end

			-- Keymaps: <leader>f = find/search operations
			vim.keymap.set("n", "<leader>ff", function()
				local opts = scope_opts()
				local ok, _ = pcall(
					builtin.git_files,
					vim.tbl_extend("force", opts, {
						show_untracked = true,
						entry_maker = file_entry_maker(opts),
					})
				)
				if not ok then
					builtin.find_files(vim.tbl_extend("force", opts, {
						hidden = true,
						entry_maker = file_entry_maker(opts),
					}))
				end
			end, { desc = "Find files" })

			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })

			vim.keymap.set("n", "<leader>fs", function()
				local opts = scope_opts()
				builtin.live_grep(vim.tbl_extend("force", opts, {
					additional_args = { "--hidden" },
					entry_maker = vimgrep_entry_maker(opts),
				}))
			end, { desc = "Live grep" })

			vim.keymap.set("n", "<leader>fo", function()
				local opts = scope_opts()
				builtin.live_grep(vim.tbl_extend("force", opts, {
					grep_open_files = true,
					prompt_title = "Live grep (open files)",
					additional_args = { "--hidden" },
					entry_maker = vimgrep_entry_maker(opts),
				}))
			end, { desc = "Live grep open files" })

			vim.keymap.set("n", "<leader>?", builtin.keymaps, { desc = "Find keymaps" })

			vim.keymap.set("n", "<leader><leader>", recent_files_picker, { desc = "Recent files" })

			vim.keymap.set("n", "<leader>fT", toggle_scope, { desc = "Toggle find scope (repo/global)" })
		end,
	},
}
