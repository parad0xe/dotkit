
-- https://github.com/kkoomen/vim-doge
local doge_ok, doge = pcall(require, 'doge')
if doge_ok then
	vim.api.nvim_create_user_command('DogeAll', function()
	  vim.cmd([[g/^\s*\(def\s\+\k\+\s*(\|class\s\+\k\+\)/DogeGenerate google]])
	  vim.cmd([[ %s/\("""\)\[TODO:summary\]\n\(\s*\)/\1\2/g ]])
	  vim.cmd([[ %s/\[TODO:description\]/\[TODO:brief_description\]/g ]])
	end, {})

	keymap('n', ' x', '<Plug>(doge-generate)', { desc = "Generate docstring for current cursor position" })
end
