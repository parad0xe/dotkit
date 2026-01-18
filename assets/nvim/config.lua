-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require('config.globals')
require('config.navigation.nvim-tree')
require('config.navigation.telescope')
require('config.code.mason')
require('config.code.lsp')
require('config.code.goto-preview')
require('config.code.docstring')
require('config.code.linter')
require('config.code.completion')
require('config.appearance.editor')
require('config.appearance.cursor')
require('config.appearance.statusbar')
require('config.appearance.animations')
require('config.tools.terminal')

keymap("n", " lg", "<cmd>LazyGit<cr>", opts)
keymap("n", " mt", "<cmd>MarkdownPreviewToggle<cr>", opts)
