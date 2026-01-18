
-- https://github.com/neovim/nvim-lspconfig
local mason_lsp_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if mason_lsp_ok then
    mason_lspconfig.setup({
        ensure_installed = { "pyright" },
    })

	vim.lsp.config('pyright', {
		on_init = function(client)
            client.config.settings.python.pythonPath = get_python_path()
        end,
		settings = {
			python = {
				analysis = {
					diagnosticMode = "workspace",
					typeCheckingMode = "strict",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
				}
			},
		},
	})
end
