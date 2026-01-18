-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require('config.globals')

-- Navigation
require('config.navigation.nvim-tree')
require('config.navigation.telescope')

-- Code
require('config.code.package-manager')
require('config.code.lsp')
require('config.code.linter')
require('config.code.format')
require('config.code.goto-preview')
require('config.code.docstring')
require('config.code.completion')

-- Appearance
require('config.appearance.theme')
require('config.appearance.cursor')
require('config.appearance.statusbar')
require('config.appearance.animations')

-- Tools
require('config.tools.terminal')

local function smart_close()
    vim.cmd("close")
    editor_focus()
end

keymap("n", "<C-q>", smart_close, { desc = "Smart close window", silent = true })

keymap("n", " lg", "<cmd>LazyGit<cr>", opts)
keymap("n", " mt", "<cmd>MarkdownPreviewToggle<cr>", opts)
