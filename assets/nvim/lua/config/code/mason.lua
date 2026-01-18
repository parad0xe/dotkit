
-- https://github.com/mason-org/mason.nvim
require("mason").setup({})

require("mason-lspconfig").setup({
  ensure_installed = { "pyright" },
})
