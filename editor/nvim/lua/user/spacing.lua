-- spacing: we default to 4 spaces unless it is in a specified list
-- (typically simple markup languages)
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.api.nvim_create_autocmd('FileType', {
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
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
  end
})
