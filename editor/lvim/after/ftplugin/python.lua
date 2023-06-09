-- allow mappings for ipython
vim.g.nvim_ipy_perform_mappings = 0

-- ipython commands in normal mode
vim.api.nvim_set_keymap('n', '<leader>jj', ':IPython<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>jk', '<Plug>(IPy-Terminate)', {})
vim.api.nvim_set_keymap('n', '<leader>jl', '<Plug>(IPy-Interrupt)', {})
vim.api.nvim_set_keymap('n', '<leader>t', '<Plug>(IPy-Run)', {})
vim.api.nvim_set_keymap('n', '<leader>r', '<Plug>(IPy-RunCell)', {})

-- ipython commands in visual mode
vim.api.nvim_set_keymap('v', '<leader>t', '<Plug>(IPy-Run)', {})
