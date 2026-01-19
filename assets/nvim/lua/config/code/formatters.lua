-- https://github.com/stevearc/conform.nvim
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
	conform.setup({
		formatters_by_ft = {
			python = { "ruff_organize_imports", "ruff_fix", "ruff_format", "yapf" },
		},

		formatters = {
			ruff_format = {
				args = {
					"format",
					"--line-length", "79",
					"--stdin-filename", "$FILENAME",
					"-",
				},
			},
			yapf = {
				prepend_args = {
					"--style",
					"{" ..
						"BASED_ON_STYLE: google," ..
						"INDENT_WIDTH: 4," ..
						"COLUMN_LIMIT: 79," ..
						"SPLIT_BEFORE_DOT: true," ..
						"SPLIT_BEFORE_DICT_SET_GENERATOR: true," ..
						"SPACES_BEFORE_COMMENT: 2," ..
						"SPLIT_BEFORE_EXPRESSION_AFTER_OPENING_PAREN: true," ..
						"SPLIT_BEFORE_FIRST_ARGUMENT: true," ..
						"COALESCE_BRACKETS: true," ..
						"DEDENT_CLOSING_BRACKETS: true," ..
						"SPLIT_ALL_COMMA_SEPARATED_VALUES: true," ..
						"SPLIT_ALL_TOP_LEVEL_COMMA_SEPARATED_VALUES: true," ..
						"SPLIT_COMPLEX_COMPREHENSION: true" ..
					"}"
				},
			},
		},

		format_on_save = {
			lsp_fallback = true,
			timeout_ms = 500,
		},
	})

	keymap({ "n", "v" }, "<C-l>", function()
		conform.format({ async = true, lsp_fallback = true })
	end, { desc = "Format file (yapf + ruff)" })
end
