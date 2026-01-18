
-- https://github.com/akinsho/toggleterm.nvim
local toggleterm_ok, toggleterm = pcall(require, "toggleterm")
if toggleterm_ok then
    toggleterm.setup({
        size = function(term)
            local lines = vim.o.lines
            local height = math.floor(lines * 0.25)
            if height < 8 then height = 8 end
            if height > 20 then height = 20 end
            return height
        end,
        direction = "horizontal",
        persist_size = true,
        persist_mode = false,
        start_in_insert = true,
        close_on_exit = true,
		hide_numbers = true,
		shade_filetypes = {},
		shade_terminals = false,
    })

	-- open terminal
	keymap("n", "<C-t>", ":ToggleTerm<CR>", { desc = "Open terminal" })

	-- close terminal
	keymap("t", "<C-t>", "<C-\\><C-n>:ToggleTerm<CR>", { desc = "Close terminal" })

	-- switch mode: normal -> terminal
	keymap("n", "<C-n>", "i", { desc = "Switch from normal to terminal mode" })

	-- switch mode: terminal -> normal
	keymap("t", "<C-n>", "<C-\\><C-n>", { desc = "Swtich from terminal to normal mode" })

	-- resize
	keymap("t", "<C-Up>", "<Cmd>resize +2<CR>", { desc = "Increase size of the terminal view" })
	keymap("t", "<C-Down>", "<Cmd>resize -2<CR>", { desc = "Decrease size of the terminal view" })
end
