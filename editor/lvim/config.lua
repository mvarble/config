-- lunarvim/nvim/vim options
lvim.log.level = "warn"
vim.opt.filetype = "on"
vim.g.loaded_python3_provider = nil
vim.o.shell = '/bin/bash'
vim.g.markdown_fenced_languages = {
  'yaml',
  'toml',
  'python',
  'julia',
  'bash',
  'sh',
  'javascript',
  'typescript',
  'typescriptreact',
  'rust',
  'cpp',
  'cmake',
}

-- user configuration
lvim.builtin.autopairs.active = false
reload("user.lsp.init")
reload("user.project")
reload("user.ui")
reload("user.spacing")
reload("user.nvim-tree")
reload("user.mappings")
