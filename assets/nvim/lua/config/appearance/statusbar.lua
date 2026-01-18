
-- https://github.com/tamton-aquib/staline.nvim
require('staline').setup({
	sections = {
        left = { '- ', '-mode', ' ', 'branch' },
        mid  = { },
        right = { 'file_name', 'cool_symbol', '-line_column' },
    },
})

