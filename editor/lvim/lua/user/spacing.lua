vim.o.autoindent = true
vim.o.cindent = true
vim.o.smartindent = true
vim.o.shiftround = true
vim.o.expandtab = true
vim.o.smarttab = true

vim.api.nvim_create_autocmd('FileType', {
  group = 'CustomTabstop',
  pattern = '*',
  callback = function()
    local filetype = vim.bo.filetype
    for _, ft in ipairs({ "yaml", "markdown", "json" }) do
      if filetype == ft then
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2
        return
      end
    end
    vim.o.tabstop = 2
    vim.o.shiftwidth = 2
  end
})
