-- change the leader
vim.g.mapleader = '\\'

-- don't highlight searches
vim.o.hlsearch = false

-- relative numbering
vim.wo.relativenumber = true

-- close program when nvim-tree is only window left
vim.api.nvim_create_autocmd('QuitPre', {
  callback = function()
    local invalid_win = {}
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
      if bufname:match('NvimTree_') ~= nil then
        table.insert(invalid_win, w)
      end
    end
    if #invalid_win == #wins - 1 then
      for _, w in ipairs(invalid_win) do vim.api.nvim_win_close(w, true) end
    end
  end
})

-- clear background
vim.g.transparency = true

-- enable python provider
vim.g.loaded_python3_provider=nil

-- fenced languages for markdown
vim.g.markdown_fenced_languages = {'yaml', 'python', 'julia', 'bash', 'sh', 'javascript', 'typescript', 'typescriptreact', 'rust', 'cpp', 'cmake', 'matlab'}

-- fish/zsh shell correction
vim.o.shell = '/bin/bash'

-- spaces
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.autoindent = true
vim.o.cindent = true
vim.o.smartindent = true
vim.o.shiftround = true
vim.o.expandtab = true
vim.o.smarttab = true

-- latex-to-unicode
vim.g.unicoder_cancel_normal = 1
vim.g.unicoder_cancel_insert = 1
vim.g.unicoder_cancel_visual = 0
