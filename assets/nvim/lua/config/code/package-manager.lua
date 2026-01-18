
-- https://github.com/mason-org/mason.nvim
local mason_ok, mason = pcall(require, "mason")
if mason_ok then
    mason.setup({})
end
