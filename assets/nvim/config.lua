local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function my_on_attach(bufnr)
	local api = require "nvim-tree.api"

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	-- default mappings
	api.config.mappings.default_on_attach(bufnr)

	-- custom mappings
	vim.keymap.set('n', ' c',     api.tree.collapse_all)
end

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

require("nvim-tree").setup({
	on_attach = my_on_attach,
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 30,
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
keymap("n", " 0", ":NvimTreeResize 30<cr>", opts)
keymap("n", " lg", "<cmd>LazyGit<cr>", opts)

local builtin = require('telescope.builtin')
vim.keymap.set('n', ' ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', ' fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', ' fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', ' fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', ' x', '<Plug>(doge-generate)')
vim.api.nvim_create_user_command('DogeAll', function()
  vim.cmd([[g/^\s*\(def\s\+\k\+\s*(\|class\s\+\k\+\)/DogeGenerate google]])
  vim.cmd([[ %s/\("""\)\[TODO:summary\]\n\(\s*\)/\1\2/g ]])
  vim.cmd([[ %s/\[TODO:description\]/\[TODO:brief_description\]/g ]])
end, {})

local ok, lint = pcall(require, "lint")
if ok then
	if vim.fn.executable("flake8") == 1 then
	  lint.linters_by_ft.python = lint.linters_by_ft.python or {}
	  table.insert(lint.linters_by_ft.python, "flake8")
	end

	if vim.fn.executable("mypy") == 1 then
	  lint.linters_by_ft.python = lint.linters_by_ft.python or {}
	  table.insert(lint.linters_by_ft.python, "mypy")

	  local mypy = lint.linters.mypy
	  mypy.args = vim.list_extend(
		  mypy.args or {},
		  { "--cache-dir=/dev/null" }
	  )
	end

	vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost", "BufNewFile" }, {
	  callback = function()
		-- ne lancer lint que si le fichier a un linter configuré
		local ft = vim.bo.filetype
		if lint.linters_by_ft[ft] then
		  lint.try_lint()
		end
	  end,
	})

	vim.diagnostic.config({
	  virtual_text = {
		prefix = "▎"--, "✖"
	  },
	  signs = true,
	  underline = false,
	  update_in_insert = false,
	  severity_sort = true,
	})

	vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ff5555" })
	vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#ff5555" })
	-- vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#f1fa8c" })

	vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff6c6b" })
	vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn",  { fg = "#ff6c6b" })
	--vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn",  { fg = "#ECBE7B" })
end

