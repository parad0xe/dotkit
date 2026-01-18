
opts = { noremap = true, silent = true }
keymap = vim.api.nvim_set_keymap

function get_python_path()
	local cwd = vim.fn.getcwd()
	local venv_py = cwd .. "/.venv/bin/python"
	if vim.fn.executable(venv_py) == 1 then
		return venv_py
	end
	return "python3"
end

