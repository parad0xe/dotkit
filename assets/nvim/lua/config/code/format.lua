
-- https://github.com/jay-babu/mason-null-ls.nvim
local mason_null_ok, mason_null_ls = pcall(require, "mason-null-ls")
if mason_null_ok then
    mason_null_ls.setup({
        ensure_installed = { "black", "isort" },
        automatic_installation = true,
    })
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim
local null_ls_ok, null_ls = pcall(require, "null-ls")
if null_ls_ok and mason_null_ok then
    local formatting = null_ls.builtins.formatting

    null_ls.setup({
        sources = {
            formatting.black,
            formatting.isort,
        },
        on_attach = function(client, bufnr)
            if client.supports_method("textDocument/formatting") then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
                })
            end
        end,
    })

	keymap({ "n", "v" }, "<C-l>", function()
		vim.lsp.buf.format({ async = true })
	end, { desc = "Format file" })
end
