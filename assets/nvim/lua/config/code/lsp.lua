
-- https://github.com/neovim/nvim-lspconfig
local mason_lsp_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if mason_lsp_ok then
    mason_lspconfig.setup()
end

if vim.fn.executable('pyright') == 1 then
	vim.lsp.config('pyright', {
		on_init = function(client)
			client.config.settings.python.pythonPath = get_python_path()
		end,
		settings = {
			python = {
				analysis = {
					diagnosticMode = "workspace",
					typeCheckingMode = "basic",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
				}
			},
		},
	})
end
