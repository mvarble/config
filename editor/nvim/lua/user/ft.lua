-- Add `.svx` as a `.md` filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.svx",
    command = "set filetype=markdown",
})

-- Treat $$ as latex
vim.treesitter.language.register("latex", "markdown")
vim.api.nvim_set_hl(0, "@latex", { link = "Special" })
vim.api.nvim_create_autocmd("BufRead", {
    pattern = { "*.md", "*.svx" },
    callback = function()
        vim.cmd([[
      syntax region texMath start=/\v^\$\$/ end=/\v\$\$$/ contains=texZone
      highlight link texMath Special
    ]])
    end,
})
