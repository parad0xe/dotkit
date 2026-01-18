
-- https://github.com/nvim-tree/nvim-tree.lua
local function my_on_attach(bufnr)
	local api = require "nvim-tree.api"

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	-- default mappings
	api.config.mappings.default_on_attach(bufnr)

	-- custom mappings
	vim.keymap.set('n', ' c',  api.tree.collapse_all)
end

require("nvim-tree").setup({
	on_attach = my_on_attach,
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 23,
	},
	update_focused_file = {
		enable = true
	},
	renderer = {
		group_empty = true,
		root_folder_label = false,
		icons = {
			web_devicons = {
				folder = {
					enable = true
				}
			}
		}
	},
	filters = {
		dotfiles = false
	},
})

keymap("n", " e", ":NvimTreeToggle<cr>", opts)
keymap("n", " f", ":NvimTreeFocus<cr>", opts)
keymap("n", " R", ":NvimTreeRefresh<cr>", opts)
keymap("n", " 1", ":NvimTreeResize 50<cr>", opts)
keymap("n", " 0", ":NvimTreeResize 23<cr>", opts)
