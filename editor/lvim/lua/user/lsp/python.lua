-- syntax
table.insert(lvim.builtin.treesitter.ensure_installed, "python")

-- plugins
table.insert(lvim.plugins, { 'bfredl/nvim-ipy' })

-- formatter
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup { { name = "black" } }

-- linter
local linters = require "lvim.lsp.null-ls.linters"
linters.setup { { command = "flake8", filetypes = { "python" } } }
