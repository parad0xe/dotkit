-- https://github.com/akinsho/toggleterm.nvim

require("toggleterm").setup({
	size = function(term)
		local lines = vim.o.lines
		local height = math.floor(lines * 0.25)
		if height < 8 then height = 8 end
		if height > 20 then height = 20 end
		return height
    end,
    direction = "horizontal",
	persist_size = true,
	persist_mode = true,
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = false,
    start_in_insert = true,
    close_on_exit = true,
})

local Terminal  = require("toggleterm.terminal").Terminal

local term1 = Terminal:new({cmd = "fish", hidden = true, direction = "horizontal"})
local term2 = Terminal:new({cmd = "fish", hidden = true, direction = "horizontal"})
local term3 = Terminal:new({cmd = "fish", hidden = true, direction = "horizontal"})

function _TERM1_TOGGLE() term1:toggle() end
function _TERM2_TOGGLE() term2:toggle() end
function _TERM3_TOGGLE() term3:toggle() end

keymap("n", "<C-1>", ":lua _TERM1_TOGGLE()<CR>", opts)
keymap("n", "<C-2>", ":lua _TERM2_TOGGLE()<CR>", opts)
keymap("n", "<C-3>", ":lua _TERM3_TOGGLE()<CR>", opts)

keymap("t", "<C-1>", "<C-\\><C-n>:lua _TERM1_TOGGLE()<CR>", opts)
keymap("t", "<C-2>", "<C-\\><C-n>:lua _TERM2_TOGGLE()<CR>", opts)
keymap("t", "<C-3>", "<C-\\><C-n>:lua _TERM3_TOGGLE()<CR>", opts)

-- open terminal
keymap("n", "<C-t>", ":ToggleTerm<CR>", opts)

-- close terminal
keymap("t", "<C-t>", "<C-\\><C-n>:ToggleTerm<CR>", opts)

-- switch mode: normal -> terminal
keymap("n", "<C-n>", "i", opts)

-- switch mode: terminal -> normal
keymap("t", "<C-n>", "<C-\\><C-n>", opts)

-- resize
keymap("t", "<C-Up>", "<Cmd>resize +2<CR>", opts)
keymap("t", "<C-Down>", "<Cmd>resize -2<CR>", opts)
