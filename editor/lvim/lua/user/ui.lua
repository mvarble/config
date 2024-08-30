-- plugins
table.insert(lvim.plugins, {
  'RRethy/nvim-base16',
  'brenoprata10/nvim-highlight-colors'
})

-- various UI properties
lvim.transparent_window = true
lvim.colorscheme = 'base16-tomorrow-night-eighties'
vim.opt.cursorline = false
vim.o.hlsearch = false
vim.wo.relativenumber = true

-- fix the LSP highlighting
vim.highlight.priorities.semantic_tokens = 95

-- wrap
vim.wo.wrap = true

-- color highlighting
vim.o.termguicolor = true
require('nvim-highlight-colors').setup {}
