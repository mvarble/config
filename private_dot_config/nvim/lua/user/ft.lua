-- Add `.svx` as a `.md` filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.svx",
    command = "set filetype=markdown",
})
