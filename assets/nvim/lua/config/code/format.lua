
-- https://github.com/jay-babu/mason-null-ls.nvim
local mason_null_ok, mason_null_ls = pcall(require, "mason-null-ls")
if mason_null_ok then
    mason_null_ls.setup({
        ensure_installed = { "yapf", "isort" },
        automatic_installation = true,
    })
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim
local null_ls_ok, null_ls = pcall(require, "null-ls")
if null_ls_ok then
    local formatting = null_ls.builtins.formatting
    null_ls.setup({
        sources = {
            formatting.yapf.with({
				extra_args = {
					"--style", 
					"{" ..
						"BASED_ON_STYLE: google," ..
                        "INDENT_WIDTH: 4," ..
                        "COLUMN_LIMIT: 79," ..
                        "SPLIT_BEFORE_DOT: true," ..
                        "SPLIT_BEFORE_DICT_SET_GENERATOR: true," ..
                        "SPACES_BEFORE_COMMENT: 1," ..
                        "SPLIT_BEFORE_EXPRESSION_AFTER_OPENING_PAREN: true," ..
                        "SPLIT_BEFORE_FIRST_ARGUMENT: true," ..
                        "COALESCE_BRACKETS: true," ..
                        "DEDENT_CLOSING_BRACKETS: true," ..
                        "SPLIT_ALL_COMMA_SEPARATED_VALUES: true," ..
                        "SPLIT_ALL_TOP_LEVEL_COMMA_SEPARATED_VALUES: true," ..
                        "SPLIT_COMPLEX_COMPREHENSION: true" ..
					"}"
				},
			}),
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
		vim.lsp.buf.format({
			filter = function(client) return client.name == "null-ls" end,
			async = true
		})
	end, { desc = "Format file" })
end
