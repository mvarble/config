-- plugins
table.insert(lvim.plugins, { 'RRethy/nvim-base16' })

-- various UI properties
lvim.transparent_window = true
lvim.colorscheme = 'base16-tomorrow-night'
vim.opt.cursorline = false
vim.o.hlsearch = false
vim.wo.relativenumber = true

-- fix the LSP highlighting
vim.highlight.priorities.semantic_tokens = 95

-- wrap
vim.wo.wrap = true
