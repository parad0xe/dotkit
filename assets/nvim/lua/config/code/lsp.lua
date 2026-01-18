
-- https://github.com/neovim/nvim-lspconfig
vim.lsp.config('pyright', {
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
