
-- https://github.com/rmagatti/goto-preview
require('goto-preview').setup({})

keymap("n", " gp", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", opts)
keymap("n", " gc", "<cmd>lua require('goto-preview').close_all_win()<CR>", opts)


