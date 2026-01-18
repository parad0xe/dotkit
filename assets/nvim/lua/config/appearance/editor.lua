
-- https://github.com/folke/tokyonight.nvim
require("tokyonight").setup({
	transparent = true
})


-- https://github.com/xiyaowong/transparent.nvim
require("transparent").setup({
	groups = { -- table: default groups
		'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
		'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
		'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
		'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
		'EndOfBuffer',
	},
	extra_groups = {
		"NormalFloat",
		"NvimTreeNormal",
		"NvimTreeNormalNC",
		"NvimTreeNormalFloat",
		"NvimTreeEndOfBuffer",
		"StatusLine",
		"StatusLineNC",
		"BufferLineTabClose",
		"BufferlineBufferSelected",
		"BufferLineFill",
		"BufferLineBackground",
		"BufferLineSeparator",
		"BufferLineIndicatorSelected",
		"IndentBlanklineChar",
		"ToggleTerm",
		"LspFloatWinNormal",
		"Normal",
		"FloatBorder", 
		"ToggleTerm",
		"TermNormal",
		"FloatBorder",
		"TelescopeNormal",
		"TelescopeBorder",
		"TelescopePromptBorder",
	}
})

vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", {
  fg = "#352d36",
  bg = "NONE"
})

vim.api.nvim_set_hl(0, "ColorColumn", {
  bg = "#3b1414"
})

keymap("n", " tt", "<cmd>TransparentToggle<cr>", opts)
