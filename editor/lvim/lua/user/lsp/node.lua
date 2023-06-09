-- syntax
table.insert(lvim.builtin.treesitter.ensure_installed, "javascript")
table.insert(lvim.builtin.treesitter.ensure_installed, "typescript")

-- formatter
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup { { name = "prettierd" } }

-- linter
local linters = require "lvim.lsp.null-ls.linters"
linters.setup { { command = "eslint", filetypes = { "javascript", "typescript" } } }
